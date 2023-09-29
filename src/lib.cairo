mod libraries {
    mod compounds;
    mod math;
    mod defences;
    mod dockyard;
    mod research;
    mod fleet;
    mod types;
}


mod game {
    mod main;
    mod interface;
}

mod token {
    mod erc20;
    mod erc721;
}

mod tests {
    mod compounds_cost_test;
    mod mines_cost_test;
    mod mines_production_test;
    mod test_fleet;
    mod view_fn_test;
    mod write_fn_test;
    mod utils;
}

