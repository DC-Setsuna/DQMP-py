#coding:utf-8
from __future__ import absolute_import

from django.shortcuts import render, render_to_response
from django.http import HttpResponse

from .celery import app
from .tasks import opt_task


from work import tasks



# def index(request):
#     hello_world.delay()
#
#     return render_to_response('index.html')

def index(request):
    # tasks.optimizer_validation.delay()
    aa = tasks.optimizer_validation.apply_async(countdown=10)
    # print("id", aa.task_id, "返回值", aa.get(), aa.result, "状态", aa.state)

    return render_to_response('index.html')


