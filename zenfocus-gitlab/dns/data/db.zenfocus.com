$TTL    604800
@       IN      SOA     zenfocus.com. admin.zenfocus.com. (
                              1         ; Serial
                         604800         ; Refresh
                          86400         ; Retry
                        2419200         ; Expire
                         604800 )       ; Negative Cache TTL

; Name servers
@       IN      NS      ns.zenfocus.com.

; A records
ns      IN      A       10.10.10.10
gitlab  IN      A       10.10.10.20
www     IN      A       10.10.10.21
