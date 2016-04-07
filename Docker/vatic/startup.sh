#!/bin/bash

mysqld&
apache2ctl graceful
/bin/bash
