use bip39::Language;

#[flutter_rust_bridge::frb(sync)]
pub fn get_english_wordlist() -> Vec<String> {
    let language = Language::English; // We only support English for now
    language
        .word_list()
        .into_iter()
        .map(|word| word.to_string())
        .collect()
}
