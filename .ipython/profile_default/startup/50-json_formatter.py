import uuid
from IPython.core.display import display, HTML
import json

class RenderJSON(object):
    def __init__(self, json_data, height=300):
        if isinstance(json_data, dict):
            self.json_str = json.dumps(json_data)
        else:
            self.json_str = json_data
        self.uuid = str(uuid.uuid4())
        self.height = height

    def _ipython_display_(self):
        display(HTML('<div id="{}" style="height: {}px; width:100%;"></div>'.format(self.uuid, self.height)))
        display(HTML("""<script>
        require(["https://rawgit.com/caldwell/renderjson/master/renderjson.js"], function() {
            renderjson.set_show_to_level(1)
            document.getElementById('%s').appendChild(renderjson(%s))
        });</script>
        """ % (self.uuid, self.json_str)))

