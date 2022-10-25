from multiprocessing import cpu_count

# Socket Path
bind = 'unix:/home/fortune/gunicorn.sock'

# Worker Options
workers = cpu_count() + 1
worker_class = 'uvicorn.workers.UvicornWorker'

# Logging Options
loglevel = 'info'
accesslog = '/home/fortune/access_log'
errorlog =  '/home/fortune/error_log'
