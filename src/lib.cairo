mod game {
    mod main;
    mod library;
    mod interface;
}

mod token {
    mod erc20;
    mod erc721;
}

mod libraries {
    mod compounds;
    mod defences;
    mod dockyard;
    mod fleet;
    mod math;
    mod packable;
    mod research;
}

#[cfg(test)]
mod test {
    mod utils;
}

