#!/bin/bash
#bdereims@vmware.com

journalctl --rotate ; journalctl --vacuum-time=2h
