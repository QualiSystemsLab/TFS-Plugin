import os
from time import sleep

duration_minutes = int(os.environ.get('TRAFFIC_DURATION_MINUTES', '1'))
load_type = os.environ.get('LOAD_TYPE', 'No load type')

print 'load type: %s' % load_type
print 'traffic duration: %d minutes' % duration_minutes
sleep(60*duration_minutes)
print 'done'