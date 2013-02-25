
// Make sidekick page actions configurable via the repository

CQ.wcm.Sidekick.DEFAULT_ACTIONS = new Array ();
CQ.wcm.Sidekick.url = "/apps/sidekick/definition.-1.json";


CQ.wcm.Sidekick.definition = CQ.HTTP.eval(CQ.wcm.Sidekick.url);

{
    var childs = CQ.wcm.Sidekick.definition.page;
    for (var c in childs) {
        var child = childs[c];
        if (typeof child == 'object') {
            CQ.wcm.Sidekick.DEFAULT_ACTIONS.push (child.action);
        }
    }
}



//// BEGIN INSERT



{
    CQ.wcm.Sidekick.CONTEXTS = new Array ();
    CQ.Log.setLevel(CQ.Log.DEBUG);
    var childs = CQ.wcm.Sidekick.definition;
    for (var c in childs) {
        var child = childs[c];
        CQ.Log.info ("type " = typeof child);
        if (typeof child != 'undefined') {
            CQ.wcm.Sidekick.CONTEXTS.push (child.name);
            CQ.Log.error ("name = " + child.name + " == " + eval(child.name));
        }
    }
}


///// END INSERT