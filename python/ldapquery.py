#!/usr/bin/env python

# Query Active Directory via LDAPS
# Authenticates using current Kerberos session
#-
# You can manually start a Kerberos sesion with kinit:
#	kinit user@CONTOSO.COM

import argparse
import gssapi
import ldap3
import ssl
import sys

parser = argparse.ArgumentParser(
		prog = "ldapquery.py",
		description = "Query Active Directory"
	)

parser.add_argument(
		"-f", "--filter",
		type = str,
		required = True,
		help = "LDAP Filter (e.g., cn=username)"
	)

parser.add_argument(
		"-b", "--base",
		type = str,
		help = "LDAP Base DN",
		default = "DC=contoso,DC=com"
	)

parser.add_argument(
		"-s", "--server",
		type = str,
		help = "LDAP Server",
		default = "server.contoso.com"
	)

parser.add_argument(
		"attributes",
		type = str,
		nargs = "*",
		help = "Attributes",
		default = [ "cn" ]
	)

args = parser.parse_args()

# LDAP filter should be wrapped '(cn=abc)'
ldapfilter = args.filter
if not ldapfilter.startswith("("):
	ldapfilter = "(" + args.filter + ")"

# CA certificate should be in trusted roots
tls = ldap3.Tls(validate = ssl.CERT_NONE,
	version = ssl.PROTOCOL_TLSv1_2,
	ca_certs_file = "/etc/pki/tls/cert.pem")

server = ldap3.Server(host = args.server,
	port = 636, use_ssl = True, tls = tls)

try:
	c = ldap3.Connection(
			server,
			auto_bind = True, version = 3, client_strategy = ldap3.SYNC,
			authentication = ldap3.SASL, sasl_mechanism = "GSSAPI",
			sasl_credentials = None
		)
except gssapi.raw.GSSError as e:
	print("Check your Kerberos tickets in cache")
	print(e)
	sys.exit()

search_parameters = {
		"search_base": args.base,
		"search_filter": ldapfilter,
		"attributes": args.attributes,
		"paged_size": 1000
	}

while True:
	try:
		c.search(**search_parameters)
	except Exception as e:
		print("Exception occured, exiting")
		print(e)
		c.unbind()
		sys.exit()
	
	for entry in c.entries:
		# records seperator
		print("#")

		# cannot use, as it outputs \uXXXX strings for unicode
		# e.g., "displayName": [ "Van Ommen, L\u00e9on" ],
		#print(entry.entry_to_json())
		
		# cannot use, as it outputs base64 strings for unicode
		# e.g., displayName: VmFuIE9tbWVuLCBMw6lvbg==
		#print(entry.entry_to_ldif())

		# so instead, we walk the attributes
		for attr in search_parameters["attributes"]:
			if len(entry[attr]) == 0:
				# empty attributes
				print(("{0}:".format(attr)))
			else:
				for item in entry[attr]:
					print(("{0}: {1}".format(attr, item)))
	
	# try and fetch new cookie
	cookie = c.result["controls"]["1.2.840.113556.1.4.319"]["value"]["cookie"]

	# loop if more results, otherwise exit
	if cookie:
		search_parameters["paged_cookie"] = cookie
	else:
		break
