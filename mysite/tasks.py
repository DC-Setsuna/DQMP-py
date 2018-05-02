from __future__ import absolute_import

from mysite.celery import app
import time

@app.task
def opt_task(fir, sec):
    time.sleep(5)
    print('running opttask')
    print(fir)
    print(sec)
    return 'done'

