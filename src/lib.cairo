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

#[cfg(test)]
mod test {
    mod utils;
}

