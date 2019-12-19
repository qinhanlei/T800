local conf = {}


-- multiple databases on single mongodb instance
conf.mongo = {
    host = "127.0.0.1",
    port = 27017,
    username = "test",
    password = "test",
    authdb = "admin",
    connects = 4,
}


-- single db on single redis instance
conf.redis = {
    host = "127.0.0.1",
    port = 6379,
    auth = "",
    connects = 4,
}


return conf
