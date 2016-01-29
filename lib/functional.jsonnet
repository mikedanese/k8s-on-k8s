{
    identity(obj)::
        obj,

    constant(k)::
        function(obj)
            k,

    bind(arr)::
        std.foldl(function(func1, func2)
                    function(obj)
                        func2(func1(obj)),
                  arr,
                  $.identity),

    nullable(func)::
        function(obj)
            if obj == null then
                null
            else
                func(obj),

    # useful for traversals
    jqSegments(path)::
        local segments = std.split(path, ".");
        local len = std.length(segments);
        if len == 0 then
            error "must pass a real path"
        else if segments[0] != "" then
            error "jq path must start with a '.'"
        else
            std.makeArray(len-1, function(i) segments[i+1]),

    # doesn't hand objects with '.' in their keys yet.
    visitField(segments, func)::
        function(obj)
            local len = std.length(segments);
            if len > 0 then
                local shorten = std.makeArray(len-1, function(i) segments[i+1]);
                {
                    [k]:
                        if k == segments[0] then
                            $.visitField(shorten, func)(obj[k]) tailstrict
                        else
                            obj[k]
                    for k in std.objectFields(obj)
                }
            else
                func(obj),

    replaceField(path, obj)::
        $.visitField($.jqSegments(path), $.constant(obj)),

    mergePatchField(path, obj)::
        $.visitField($.jqSegments(path), function(target) std.mergePatch(target, obj)),
}
