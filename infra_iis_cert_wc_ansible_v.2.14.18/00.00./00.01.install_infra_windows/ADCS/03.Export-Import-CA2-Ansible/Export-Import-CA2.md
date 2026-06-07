
# SUR CA Windows - EXPORT encodé base 64

# Puis sur ANSIBLE:
# Attention extension .cer vers .crt
admin_ansible@master-03:/projet_optimedit/Git$ sudo cp Optimedit-Root-CA2.cer /usr/local/share/ca-certificates/Optimedit-Root-CA2.crt

admin_ansible@master-03:/projet_optimedit/Git$ ls -l /usr/local/share/ca-certificates/
total 8
-rw-r--r-- 1 root root 1966 28 mai   21:56 Optimedit-Root-CA2.crt

admin_ansible@master-03:/projet_optimedit/Git$ sudo update-ca-certificates --fresh
Clearing symlinks in /etc/ssl/certs...
done.
Updating certificates in /etc/ssl/certs...
rehash: warning: skipping Optimedit-CA2.pem,it does not contain exactly one certificate or CRL
rehash: warning: skipping ca-certificates.crt,it does not contain exactly one certificate or CRL
144 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.


admin_ansible@master-03:/projet_optimedit/Git$ sudo update-ca-certificates
Updating certificates in /etc/ssl/certs...
0 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.

# Attention extension .pem
admin_ansible@master-03:/projet_optimedit/Git$ ls -l /etc/ssl/certs/Optimedit-Root-CA2.pem
lrwxrwxrwx 1 root root 55 28 mai   21:56 /etc/ssl/certs/Optimedit-Root-CA2.pem -> /usr/local/share/ca-certificates/Optimedit-Root-CA2.crt
admin_ansible@master-03:/projet_optimedit/Git$



#### VALIDATION
admin_ansible@master-03:/projet_optimedit/Git$ openssl s_client -connect opt-iis-01.optimedit.eu:5986 -CAfile /etc/ssl/certs/ca-certificates.crt
CONNECTED(00000003)
depth=1 DC = eu, DC = optimedit, CN = Optimedit-CA2 # 1 = Ok
verify return:1
depth=0 CN = OPT-IIS-01.optimedit.eu # 0 = Ok
verify return:1
...
---
SSL handshake has read 2168 bytes and written 409 bytes
Verification: OK # ICI
---
####




admin_ansible@master-03:/projet_optimedit/Git$ ./00.00.audit_winrm_certs/audit_winrm_certs_with_group_vars.sh
=== DEBUT DE L'AUDIT DYNAMIQUE DES GROUPES ANSIBLE ===

👉 Groupe : [srv_adcs] (1 serveurs)
FQDN                      | THUMBPRINT                                 | EXPIRATION                | STATUS
------------------------------------------------------------------------------------------------------------------------
OPT-DC02.optimedit.eu     | A41320D50F5E9CE395207F341CCFE430FACEEA92   | Aug 26 10:20:02 2026 GMT  | VALIDE
------------------------------------------------------------------------------------------------------------------------
[OK] Rapport généré : /projet_optimedit/Git/00.00.audit_winrm_certs/csv_result/audit_winrm_srv_adcs_20260528_2200.csv

👉 Groupe : [srv_dc] (1 serveurs)
FQDN                      | THUMBPRINT                                 | EXPIRATION                | STATUS
------------------------------------------------------------------------------------------------------------------------
OPT-DC02.optimedit.eu     | A41320D50F5E9CE395207F341CCFE430FACEEA92   | Aug 26 10:20:02 2026 GMT  | VALIDE
------------------------------------------------------------------------------------------------------------------------
[OK] Rapport généré : /projet_optimedit/Git/00.00.audit_winrm_certs/csv_result/audit_winrm_srv_dc_20260528_2200.csv

👉 Groupe : [srv_fs] (1 serveurs)
FQDN                      | THUMBPRINT                                 | EXPIRATION                | STATUS
------------------------------------------------------------------------------------------------------------------------
OPT-FS02.optimedit.eu     | 8139F61195B16656B15B0CE2F50E2F5C8A8F4318   | Aug 26 10:33:00 2026 GMT  | VALIDE
------------------------------------------------------------------------------------------------------------------------
[OK] Rapport généré : /projet_optimedit/Git/00.00.audit_winrm_certs/csv_result/audit_winrm_srv_fs_20260528_2200.csv

👉 Groupe : [srv_iis] (4 serveurs)
FQDN                      | THUMBPRINT                                 | EXPIRATION                | STATUS
------------------------------------------------------------------------------------------------------------------------
OPT-IIS-01.optimedit.eu   | 8D129CEE8CA5EA2170DF548E166EACEF4A4EE24E   | Aug 26 10:46:43 2026 GMT  | VALIDE
OPT-IIS-02.optimedit.eu   | 225F7F7BBDF9C538C240779D44DA45342B3832C2   | Aug 26 13:51:01 2026 GMT  | VALIDE
OPT-IIS-03.optimedit.eu   | C92FDAEA2BAB63A92E94201A7D1C1F99A801D1D7   | Aug 26 14:04:08 2026 GMT  | VALIDE
OPT-IIS-04.optimedit.eu   | 785F631F6574F0EC4835097E98D5E330EC69E31C   | Aug 26 14:50:03 2026 GMT  | VALIDE
------------------------------------------------------------------------------------------------------------------------
[OK] Rapport généré : /projet_optimedit/Git/00.00.audit_winrm_certs/csv_result/audit_winrm_srv_iis_20260528_2200.csv

=== FIN DE L'AUDIT GLOBAL ===
admin_ansible@master-03:/projet_optimedit/Git$


##########  VALIDATION ET TEST
admin_ansible@master-03:/projet_optimedit/Git$ cat group_vars/all.yml
---
# Emplacment /projet_optimedit/Git/group_vars/all.yml
ansible_user: admin_ansible@OPTIMEDIT.EU
ansible_password: "Dr/*-101977"
ansible_connection: winrm
ansible_winrm_transport: kerberos
ansible_winrm_scheme: https
ansible_port: 5986
ansible_winrm_server_cert_validation: validate # ICI
....
# 
admin_ansible@master-03:/projet_optimedit/Git$ ansible srv_iis -m win_ping
OPT-IIS-01.optimedit.eu | SUCCESS => { # SUCCESS
    "changed": false, 
    "ping": "pong"
}
OPT-IIS-02.optimedit.eu | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
OPT-IIS-04.optimedit.eu | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
OPT-IIS-03.optimedit.eu | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
admin_ansible@master-03:/projet_optimedit/Git$

