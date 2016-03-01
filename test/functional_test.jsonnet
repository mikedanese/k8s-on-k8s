local functional = import "lib/functional.jsonnet";

local blah = {
    foo: {
        bar: "blah",
    },
};

local out = functional.bind([
    functional.replaceField(".foo.bar", { bing: "bang" }),
    functional.mergePatchField(".foo.bar", { baz: "dingus" }),
])(blah);

std.assertEqual(out, {
   foo: {
      bar: {
         baz: "dingus",
         bing: "bang",
      },
   },
})
