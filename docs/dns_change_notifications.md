
# DNS Change Notifications via DirectAdmin Hooks

- `all_pre.sh` detects `/CMD_DNS_ADMIN` saves and copies the old zone.
- `dns_write_post.sh` diffs old vs new and emails the owner.

Deploy:
```bash
sudo install -d -m 0755 /usr/local/directadmin/scripts/custom
sudo cp scripts/hooks/all_pre.sh scripts/hooks/dns_write_post.sh /usr/local/directadmin/scripts/custom/
sudo chmod 755 /usr/local/directadmin/scripts/custom/all_pre.sh /usr/local/directadmin/scripts/custom/dns_write_post.sh
```
