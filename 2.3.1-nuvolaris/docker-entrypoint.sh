#!/bin/bash
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

set -e

if [ ! -z "$NODENAME" ] && ! grep "couchdb@" /opt/couchdb/etc/vm.args; then
	echo "-name couchdb@$NODENAME" >> /opt/couchdb/etc/vm.args
fi

if [ "$COUCHDB_USER" ] && [ "$COUCHDB_PASSWORD" ]; then
	# Create admin only if not already present
	if ! grep -Pzoqr "\[admins\]\n$COUCHDB_USER =" /opt/couchdb/etc/local.d/*.ini /opt/couchdb/etc/local.ini 2>/dev/null; then
		printf "\n[admins]\n%s = %s\n" "$COUCHDB_USER" "$COUCHDB_PASSWORD" >> /opt/couchdb/etc/local.d/docker.ini
	fi
fi

if [ "$COUCHDB_SECRET" ]; then
	# Set secret only if not already present
	if ! grep -Pzoqr "\[couch_httpd_auth\]\nsecret =" /opt/couchdb/etc/local.d/*.ini /opt/couchdb/etc/local.ini; then
		printf "\n[couch_httpd_auth]\nsecret = %s\n" "$COUCHDB_SECRET" >> /opt/couchdb/etc/local.d/docker.ini
	fi
fi

# if we don't find an [admins] section followed by a non-comment, display a warning
if ! grep -Pzoqr '\[admins\]\n[^;]\w+' /opt/couchdb/etc/default.d/*.ini /opt/couchdb/etc/local.d/*.ini /opt/couchdb/etc/local.ini; then
# The - option suppresses leading tabs but *not* spaces. :)
cat >&2 <<-'EOWARN'
		****************************************************
		WARNING: CouchDB is running in Admin Party mode.
					This will allow anyone with access to the
					CouchDB port to access your database. In
					Docker's default configuration, this is
					effectively any other container on the same
					system.
					Use "-e COUCHDB_USER=admin -e COUCHDB_PASSWORD=password"
					to set it in "docker run".
		****************************************************
	EOWARN
fi

if test -e /opt/couchdb/data/.erlang.cookie
then chmod 400 /opt/couchdb/data/.erlang.cookie
fi
exec /opt/couchdb/bin/couchdb "$@"
