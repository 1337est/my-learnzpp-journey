Running `zig build --summary all` gives me this the first time around:

```
Build Summary: 3/3 steps succeeded
install success
└─ install hello success
   └─ compile exe hello Debug native success 254ms MaxRSS:139M
```

It also created this directory structure:
```
.
├── .zig-cache
│   ├── h
│   │   ├── 9e8eaef33cdfdb98f33ac2f579674b32.txt
│   │   ├── a2493a71b18c72791f998bfa9865d9fd.txt
│   │   └── timestamp
│   ├── o
│   │   ├── 69ab76f63599d792299b23e6db652bf5
│   │   │   └── hello
│   │   ├── 864ec81a21c81c805976d13e3f05f512
│   │   │   └── build
│   │   └── f1ea4330472a4c6ebcbfed6922919020
│   │       └── dependencies.zig
│   ├── tmp
│   └── z
│       ├── 0de2bc7b8ecf843738d5e3b13139ce2e
│       ├── 1ac0ef8c03ccafd318b0727843841768
│       └── efb08ba0344ccd30d8fe332fee75d791
└── zig-out
    └── bin
        └── hello
```

Running it a second time, immediately after gives me this:
```
Build Summary: 3/3 steps succeeded
install cached
└─ install hello cached
   └─ compile exe hello Debug native cached 23ms MaxRSS:55M
```

The cached section is eluding to the creation of the `.zig-cache` directory. 
