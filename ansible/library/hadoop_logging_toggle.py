#!/usr/bin/python3
# -*- coding: utf-8 -*-
# Copyright (c) 2025. Apache 2.0 License.

"""
Ansible module for granular Hadoop ecosystem logging toggle control.
"""

from __future__ import absolute_import, division, print_function

__metaclass__ = type

ANSIBLE_METADATA = {
    "metadata_version": "1.1",
    "status": ["preview"],
    "supported_by": "community",
}

DOCUMENTATION = r"""
---
module: hadoop_logging_toggle
short_description: Set Hadoop ecosystem logging component toggles
description:
  - Modifies logging configuration for Hadoop components (MapReduce, Hive, HBase, Pig, etc.).
  - Supports mapreduce_hs_audit, mapreduce_shuffle_audit, router_audit, nm_audit,
    namenode_metrics, datanode_metrics, hive, hbase, pig.
version_added: "1.0.0"
options:
  component:
    description: The logging component to toggle.
    required: true
    type: str
    choices:
      - mapreduce_hs_audit
      - mapreduce_shuffle_audit
      - router_audit
      - nm_audit
      - namenode_metrics
      - datanode_metrics
      - hive
      - hbase
      - pig
  value:
    description: Log level or state (OFF, INFO).
    required: true
    type: str
    choices:
      - OFF
      - INFO
  config_path:
    description: Path to hadoop-conf directory.
    required: false
    type: path
    default: ./hadoop-conf
author:
  - spark-hadoop
"""

EXAMPLES = r"""
- name: Enable MapReduce JobHistory audit
  hadoop_logging_toggle:
    component: mapreduce_hs_audit
    value: INFO
    config_path: /opt/spark-hadoop-config/hadoop-conf

- name: Disable NodeManager audit
  hadoop_logging_toggle:
    component: nm_audit
    value: OFF
"""

RETURN = r"""
changed:
  description: Whether the configuration was modified.
  returned: always
  type: bool
component:
  description: The component that was toggled.
  returned: always
  type: str
value:
  description: The value that was set.
  returned: always
  type: str
message:
  description: Human-readable status message.
  returned: always
  type: str
"""

import os
import re

from ansible.module_utils.basic import AnsibleModule


# Map component to (file, property_name, env_var or pattern)
COMPONENT_CONFIG = {
    "mapreduce_hs_audit": ("mapred-env.sh", "mapreduce.hs.audit.logger", "MAPRED_HISTORYSERVER_OPTS"),
    "mapreduce_shuffle_audit": ("mapred-env.sh", "mapreduce.shuffle.audit.logger", None),
    "router_audit": ("yarn-env.sh", "router.audit.logger", "YARN_ROUTER_OPTS"),
    "nm_audit": ("yarn-env.sh", "nm.audit.logger", "YARN_NODEMANAGER_OPTS"),
    "namenode_metrics": ("hdfs-env.sh", "namenode.metrics.logger", "HDFS_NAMENODE_OPTS"),
    "datanode_metrics": ("hdfs-env.sh", "datanode.metrics.logger", "HDFS_DATANODE_OPTS"),
    "hive": (None, None, None),
    "hbase": (None, None, None),
    "pig": (None, None, None),
}


def apply_mapred_audit(module, config_path, value):
    """Apply MapReduce JobHistory audit toggle to mapred-env.sh."""
    filepath = os.path.join(config_path, "mapred-env.sh")
    if not os.path.exists(filepath):
        module.fail_json(msg=f"File not found: {filepath}")

    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    if value == "INFO":
        new_line = 'export MAPRED_HISTORYSERVER_OPTS="${MAPRED_HISTORYSERVER_OPTS:-} -Dmapreduce.hs.audit.logger=INFO -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=1030"'
    else:
        new_line = 'export MAPRED_HISTORYSERVER_OPTS="-Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.port=1030"'

    has_audit = bool(re.search(r"mapreduce\.hs\.audit\.logger=INFO", content))
    wants_audit = value == "INFO"

    if has_audit == wants_audit:
        return False

    # Replace the MAPRED_HISTORYSERVER_OPTS line
    content = re.sub(
        r'export MAPRED_HISTORYSERVER_OPTS="[^"]*"',
        new_line,
        content,
        count=1,
    )
    if not re.search(r"export MAPRED_HISTORYSERVER_OPTS=", content):
        content = content.rstrip() + "\n" + new_line + "\n"

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

    return True


def run_module():
    """Execute the hadoop_logging_toggle module."""
    module_args = dict(
        component=dict(type="str", required=True, choices=list(COMPONENT_CONFIG)),
        value=dict(type="str", required=True, choices=["OFF", "INFO"]),
        config_path=dict(type="path", required=False, default="./hadoop-conf"),
    )

    result = dict(changed=False, component="", value="", message="")

    module = AnsibleModule(argument_spec=module_args, supports_check_mode=True)

    component = module.params["component"]
    value = module.params["value"]
    config_path = module.params["config_path"]

    result["component"] = component
    result["value"] = value

    if component not in COMPONENT_CONFIG:
        module.fail_json(msg=f"Unknown component: {component}", **result)

    config = COMPONENT_CONFIG[component]
    if config[0] is None:
        module.exit_json(
            msg=f"Component {component} not yet implemented (Hive/HBase/Pig)",
            changed=False,
            **result,
        )

    if component == "mapreduce_hs_audit":
        if module.check_mode:
            result["message"] = f"Would set {component} to {value}"
            module.exit_json(**result)
        result["changed"] = apply_mapred_audit(module, config_path, value)
        result["message"] = f"Set {component} to {value}"
        module.exit_json(**result)

    result["message"] = f"Component {component} toggle not yet implemented"
    module.exit_json(**result)


if __name__ == "__main__":
    run_module()
