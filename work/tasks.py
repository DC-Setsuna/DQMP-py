from __future__ import absolute_import
from celery import shared_task

import ibm_db
import os
import sys
import json
import datetime



class DateEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, datetime.datetime):
            return obj.strftime('%Y-%m-%d %H-%M-%S')
        elif isinstance(obj, datetime.date):
            return obj.strftime('%Y-%m-%d')
        else:
            return json.JSONEncoder.default(self, obj)


@shared_task
def optimizer_validation():
    # print(sys.path)
    config = open(sys.path[-1] + '/work/config.json', 'r')
    config = config.read()
    config = json.loads(config)
    dns = "DATABASE=%s;HOSTNAME=%s;PORT=%s;PROTOCOL=TCPIP;UID=%s;PWD=%s" % (config['database'], config['hostname'], config['port'], config['user_id'], config['password'])
    conn = ibm_db.connect(dns, "", "")

    print(sys.path[-1])  # /Users/apple/Desktop/test

    sqlfiles = os.listdir(sys.path[-1] + '/work/sql')

    for sqlfile in sqlfiles:
        if not sqlfile.endswith('.sql'):
            sqlfiles.remove(sqlfile)

    print('**** %d SQL FILE' % len(sqlfiles))

    count_list = open(sys.path[-1] + '/work/datas/count-list.txt', 'w')
    detail = {}

    for sqlfile_name in sqlfiles:
        count = 0
        print('**** running %d / %d : %s' % ((sqlfiles.index(sqlfile_name) + 1), len(sqlfiles), sqlfile_name))
        data_file = open((sys.path[-1] + '/work/datas/%s.txt' % sqlfile_name), 'w')
        sqlfile = open(sys.path[-1] + '/work/sql/' + sqlfile_name)
        sql = sqlfile.read()
        stmt = ibm_db.exec_immediate(conn, sql)
        result = ibm_db.fetch_assoc(stmt)
        while (result):
            data_file.write(json.dumps(result, cls=DateEncoder))
            data_file.write('\n')
            result = ibm_db.fetch_assoc(stmt)
            count = count + 1
        detail.setdefault(sqlfile_name, count)
        data_file.close()
        sqlfile.close()

    count_list.write(json.dumps(detail, cls=DateEncoder))
    count_list.close()