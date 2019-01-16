import os
import json
def app(environ, response):
    statusUpdate = {}
    statusUpdate['status'] = 'ok'
    statusUpdate['buildNumber'] = os.environ.get('BUILD_NUMBER') or "BUILD NUMBER NOT FOUND"
    statusUpdate['executionSpace'] = os.environ.get('EXECUTE_SPACE') or "NO EXECUTION SPACE FOUND"
    data = bytes(json.dumps(statusUpdate))
    response("200 OK", [
        ("Content-Type", "application/json"),
        ("Content-Length", str(len(data)))
    ])
    return iter([data])