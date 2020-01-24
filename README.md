freehck.script_send_datadog
=========

This role copies the script that send metrics to datadog.

Useful in other scripts.

Role Variables
--------------
`send_datadog_script_dir`: directory to install the script, default "/opt/scripts"

`send_datadog_script_name`: script name, default "send-datadog"

`send_datadog_install_deps`: install dependencies (moreutils), default "yes"

Example Playbook
----------------

    - hosts:
        - load_balancers
      become: yes
      roles:
        - role: freehck.script_send_datadog

License
-------
MIT

Author Information
------------------
Dmitrii Kashin, <freehck@freehck.ru>
