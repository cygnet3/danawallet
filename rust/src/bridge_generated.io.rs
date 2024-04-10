use super::*;
// Section: wire functions

#[no_mangle]
pub extern "C" fn wire_create_log_stream(port_: i64, level: i32, log_dependencies: bool) {
    wire_create_log_stream_impl(port_, level, log_dependencies)
}

#[no_mangle]
pub extern "C" fn wire_create_sync_stream(port_: i64) {
    wire_create_sync_stream_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_create_scan_progress_stream(port_: i64) {
    wire_create_scan_progress_stream_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_create_amount_stream(port_: i64) {
    wire_create_amount_stream_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_create_nakamoto_run_stream(port_: i64) {
    wire_create_nakamoto_run_stream_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_wallet_exists(
    port_: i64,
    label: *mut wire_uint_8_list,
    files_dir: *mut wire_uint_8_list,
) {
    wire_wallet_exists_impl(port_, label, files_dir)
}

#[no_mangle]
pub extern "C" fn wire_setup_nakamoto(
    port_: i64,
    network: *mut wire_uint_8_list,
    path: *mut wire_uint_8_list,
) {
    wire_setup_nakamoto_impl(port_, network, path)
}

#[no_mangle]
pub extern "C" fn wire_clean_nakamoto(port_: i64) {
    wire_clean_nakamoto_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_setup(
    port_: i64,
    label: *mut wire_uint_8_list,
    files_dir: *mut wire_uint_8_list,
    wallet_type: *mut wire_WalletType,
    birthday: u32,
    is_testnet: bool,
) {
    wire_setup_impl(port_, label, files_dir, wallet_type, birthday, is_testnet)
}

#[no_mangle]
pub extern "C" fn wire_change_birthday(
    port_: i64,
    path: *mut wire_uint_8_list,
    label: *mut wire_uint_8_list,
    birthday: u32,
) {
    wire_change_birthday_impl(port_, path, label, birthday)
}

#[no_mangle]
pub extern "C" fn wire_reset_wallet(
    port_: i64,
    path: *mut wire_uint_8_list,
    label: *mut wire_uint_8_list,
) {
    wire_reset_wallet_impl(port_, path, label)
}

#[no_mangle]
pub extern "C" fn wire_remove_wallet(
    port_: i64,
    path: *mut wire_uint_8_list,
    label: *mut wire_uint_8_list,
) {
    wire_remove_wallet_impl(port_, path, label)
}

#[no_mangle]
pub extern "C" fn wire_sync_blockchain(port_: i64) {
    wire_sync_blockchain_impl(port_)
}

#[no_mangle]
pub extern "C" fn wire_scan_to_tip(
    port_: i64,
    path: *mut wire_uint_8_list,
    label: *mut wire_uint_8_list,
) {
    wire_scan_to_tip_impl(port_, path, label)
}

#[no_mangle]
pub extern "C" fn wire_get_wallet_info(
    port_: i64,
    path: *mut wire_uint_8_list,
    label: *mut wire_uint_8_list,
) {
    wire_get_wallet_info_impl(port_, path, label)
}

#[no_mangle]
pub extern "C" fn wire_get_receiving_address(
    port_: i64,
    path: *mut wire_uint_8_list,
    label: *mut wire_uint_8_list,
) {
    wire_get_receiving_address_impl(port_, path, label)
}

#[no_mangle]
pub extern "C" fn wire_get_spendable_outputs(
    port_: i64,
    path: *mut wire_uint_8_list,
    label: *mut wire_uint_8_list,
) {
    wire_get_spendable_outputs_impl(port_, path, label)
}

#[no_mangle]
pub extern "C" fn wire_get_outputs(
    port_: i64,
    path: *mut wire_uint_8_list,
    label: *mut wire_uint_8_list,
) {
    wire_get_outputs_impl(port_, path, label)
}

#[no_mangle]
pub extern "C" fn wire_create_new_psbt(
    port_: i64,
    label: *mut wire_uint_8_list,
    path: *mut wire_uint_8_list,
    inputs: *mut wire_list_owned_output,
    recipients: *mut wire_list_recipient,
) {
    wire_create_new_psbt_impl(port_, label, path, inputs, recipients)
}

#[no_mangle]
pub extern "C" fn wire_add_fee_for_fee_rate(
    port_: i64,
    psbt: *mut wire_uint_8_list,
    fee_rate: u32,
    payer: *mut wire_uint_8_list,
) {
    wire_add_fee_for_fee_rate_impl(port_, psbt, fee_rate, payer)
}

#[no_mangle]
pub extern "C" fn wire_fill_sp_outputs(
    port_: i64,
    path: *mut wire_uint_8_list,
    label: *mut wire_uint_8_list,
    psbt: *mut wire_uint_8_list,
) {
    wire_fill_sp_outputs_impl(port_, path, label, psbt)
}

#[no_mangle]
pub extern "C" fn wire_sign_psbt(
    port_: i64,
    path: *mut wire_uint_8_list,
    label: *mut wire_uint_8_list,
    psbt: *mut wire_uint_8_list,
    finalize: bool,
) {
    wire_sign_psbt_impl(port_, path, label, psbt, finalize)
}

#[no_mangle]
pub extern "C" fn wire_extract_tx_from_psbt(port_: i64, psbt: *mut wire_uint_8_list) {
    wire_extract_tx_from_psbt_impl(port_, psbt)
}

#[no_mangle]
pub extern "C" fn wire_broadcast_tx(port_: i64, tx: *mut wire_uint_8_list) {
    wire_broadcast_tx_impl(port_, tx)
}

#[no_mangle]
pub extern "C" fn wire_mark_transaction_inputs_as_spent(
    port_: i64,
    path: *mut wire_uint_8_list,
    label: *mut wire_uint_8_list,
    tx: *mut wire_uint_8_list,
) {
    wire_mark_transaction_inputs_as_spent_impl(port_, path, label, tx)
}

#[no_mangle]
pub extern "C" fn wire_show_mnemonic(
    port_: i64,
    path: *mut wire_uint_8_list,
    label: *mut wire_uint_8_list,
) {
    wire_show_mnemonic_impl(port_, path, label)
}

// Section: allocate functions

#[no_mangle]
pub extern "C" fn new_box_autoadd_wallet_type_0() -> *mut wire_WalletType {
    support::new_leak_box_ptr(wire_WalletType::new_with_null_ptr())
}

#[no_mangle]
pub extern "C" fn new_list_owned_output_0(len: i32) -> *mut wire_list_owned_output {
    let wrap = wire_list_owned_output {
        ptr: support::new_leak_vec_ptr(<wire_OwnedOutput>::new_with_null_ptr(), len),
        len,
    };
    support::new_leak_box_ptr(wrap)
}

#[no_mangle]
pub extern "C" fn new_list_recipient_0(len: i32) -> *mut wire_list_recipient {
    let wrap = wire_list_recipient {
        ptr: support::new_leak_vec_ptr(<wire_Recipient>::new_with_null_ptr(), len),
        len,
    };
    support::new_leak_box_ptr(wrap)
}

#[no_mangle]
pub extern "C" fn new_uint_8_list_0(len: i32) -> *mut wire_uint_8_list {
    let ans = wire_uint_8_list {
        ptr: support::new_leak_vec_ptr(Default::default(), len),
        len,
    };
    support::new_leak_box_ptr(ans)
}

// Section: related functions

// Section: impl Wire2Api

impl Wire2Api<String> for *mut wire_uint_8_list {
    fn wire2api(self) -> String {
        let vec: Vec<u8> = self.wire2api();
        String::from_utf8_lossy(&vec).into_owned()
    }
}

impl Wire2Api<WalletType> for *mut wire_WalletType {
    fn wire2api(self) -> WalletType {
        let wrap = unsafe { support::box_from_leak_ptr(self) };
        Wire2Api::<WalletType>::wire2api(*wrap).into()
    }
}

impl Wire2Api<Vec<OwnedOutput>> for *mut wire_list_owned_output {
    fn wire2api(self) -> Vec<OwnedOutput> {
        let vec = unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        };
        vec.into_iter().map(Wire2Api::wire2api).collect()
    }
}
impl Wire2Api<Vec<Recipient>> for *mut wire_list_recipient {
    fn wire2api(self) -> Vec<Recipient> {
        let vec = unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        };
        vec.into_iter().map(Wire2Api::wire2api).collect()
    }
}

impl Wire2Api<OutputSpendStatus> for wire_OutputSpendStatus {
    fn wire2api(self) -> OutputSpendStatus {
        match self.tag {
            0 => OutputSpendStatus::Unspent,
            1 => unsafe {
                let ans = support::box_from_leak_ptr(self.kind);
                let ans = support::box_from_leak_ptr(ans.Spent);
                OutputSpendStatus::Spent(ans.field0.wire2api())
            },
            2 => unsafe {
                let ans = support::box_from_leak_ptr(self.kind);
                let ans = support::box_from_leak_ptr(ans.Mined);
                OutputSpendStatus::Mined(ans.field0.wire2api())
            },
            _ => unreachable!(),
        }
    }
}
impl Wire2Api<OwnedOutput> for wire_OwnedOutput {
    fn wire2api(self) -> OwnedOutput {
        OwnedOutput {
            txoutpoint: self.txoutpoint.wire2api(),
            blockheight: self.blockheight.wire2api(),
            tweak: self.tweak.wire2api(),
            amount: self.amount.wire2api(),
            script: self.script.wire2api(),
            label: self.label.wire2api(),
            spend_status: self.spend_status.wire2api(),
        }
    }
}
impl Wire2Api<Recipient> for wire_Recipient {
    fn wire2api(self) -> Recipient {
        Recipient {
            address: self.address.wire2api(),
            amount: self.amount.wire2api(),
            nb_outputs: self.nb_outputs.wire2api(),
        }
    }
}

impl Wire2Api<Vec<u8>> for *mut wire_uint_8_list {
    fn wire2api(self) -> Vec<u8> {
        unsafe {
            let wrap = support::box_from_leak_ptr(self);
            support::vec_from_leak_ptr(wrap.ptr, wrap.len)
        }
    }
}
impl Wire2Api<WalletType> for wire_WalletType {
    fn wire2api(self) -> WalletType {
        match self.tag {
            0 => WalletType::New,
            1 => unsafe {
                let ans = support::box_from_leak_ptr(self.kind);
                let ans = support::box_from_leak_ptr(ans.Mnemonic);
                WalletType::Mnemonic(ans.field0.wire2api())
            },
            2 => unsafe {
                let ans = support::box_from_leak_ptr(self.kind);
                let ans = support::box_from_leak_ptr(ans.PrivateKeys);
                WalletType::PrivateKeys(ans.field0.wire2api(), ans.field1.wire2api())
            },
            3 => unsafe {
                let ans = support::box_from_leak_ptr(self.kind);
                let ans = support::box_from_leak_ptr(ans.ReadOnly);
                WalletType::ReadOnly(ans.field0.wire2api(), ans.field1.wire2api())
            },
            _ => unreachable!(),
        }
    }
}
// Section: wire structs

#[repr(C)]
#[derive(Clone)]
pub struct wire_list_owned_output {
    ptr: *mut wire_OwnedOutput,
    len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_list_recipient {
    ptr: *mut wire_Recipient,
    len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_OwnedOutput {
    txoutpoint: *mut wire_uint_8_list,
    blockheight: u32,
    tweak: *mut wire_uint_8_list,
    amount: u64,
    script: *mut wire_uint_8_list,
    label: *mut wire_uint_8_list,
    spend_status: wire_OutputSpendStatus,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_Recipient {
    address: *mut wire_uint_8_list,
    amount: u64,
    nb_outputs: u32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_uint_8_list {
    ptr: *mut u8,
    len: i32,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_OutputSpendStatus {
    tag: i32,
    kind: *mut OutputSpendStatusKind,
}

#[repr(C)]
pub union OutputSpendStatusKind {
    Unspent: *mut wire_OutputSpendStatus_Unspent,
    Spent: *mut wire_OutputSpendStatus_Spent,
    Mined: *mut wire_OutputSpendStatus_Mined,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_OutputSpendStatus_Unspent {}

#[repr(C)]
#[derive(Clone)]
pub struct wire_OutputSpendStatus_Spent {
    field0: *mut wire_uint_8_list,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_OutputSpendStatus_Mined {
    field0: *mut wire_uint_8_list,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_WalletType {
    tag: i32,
    kind: *mut WalletTypeKind,
}

#[repr(C)]
pub union WalletTypeKind {
    New: *mut wire_WalletType_New,
    Mnemonic: *mut wire_WalletType_Mnemonic,
    PrivateKeys: *mut wire_WalletType_PrivateKeys,
    ReadOnly: *mut wire_WalletType_ReadOnly,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_WalletType_New {}

#[repr(C)]
#[derive(Clone)]
pub struct wire_WalletType_Mnemonic {
    field0: *mut wire_uint_8_list,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_WalletType_PrivateKeys {
    field0: *mut wire_uint_8_list,
    field1: *mut wire_uint_8_list,
}

#[repr(C)]
#[derive(Clone)]
pub struct wire_WalletType_ReadOnly {
    field0: *mut wire_uint_8_list,
    field1: *mut wire_uint_8_list,
}
// Section: impl NewWithNullPtr

pub trait NewWithNullPtr {
    fn new_with_null_ptr() -> Self;
}

impl<T> NewWithNullPtr for *mut T {
    fn new_with_null_ptr() -> Self {
        std::ptr::null_mut()
    }
}

impl Default for wire_OutputSpendStatus {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_OutputSpendStatus {
    fn new_with_null_ptr() -> Self {
        Self {
            tag: -1,
            kind: core::ptr::null_mut(),
        }
    }
}

#[no_mangle]
pub extern "C" fn inflate_OutputSpendStatus_Spent() -> *mut OutputSpendStatusKind {
    support::new_leak_box_ptr(OutputSpendStatusKind {
        Spent: support::new_leak_box_ptr(wire_OutputSpendStatus_Spent {
            field0: core::ptr::null_mut(),
        }),
    })
}

#[no_mangle]
pub extern "C" fn inflate_OutputSpendStatus_Mined() -> *mut OutputSpendStatusKind {
    support::new_leak_box_ptr(OutputSpendStatusKind {
        Mined: support::new_leak_box_ptr(wire_OutputSpendStatus_Mined {
            field0: core::ptr::null_mut(),
        }),
    })
}

impl NewWithNullPtr for wire_OwnedOutput {
    fn new_with_null_ptr() -> Self {
        Self {
            txoutpoint: core::ptr::null_mut(),
            blockheight: Default::default(),
            tweak: core::ptr::null_mut(),
            amount: Default::default(),
            script: core::ptr::null_mut(),
            label: core::ptr::null_mut(),
            spend_status: Default::default(),
        }
    }
}

impl Default for wire_OwnedOutput {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_Recipient {
    fn new_with_null_ptr() -> Self {
        Self {
            address: core::ptr::null_mut(),
            amount: Default::default(),
            nb_outputs: Default::default(),
        }
    }
}

impl Default for wire_Recipient {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl Default for wire_WalletType {
    fn default() -> Self {
        Self::new_with_null_ptr()
    }
}

impl NewWithNullPtr for wire_WalletType {
    fn new_with_null_ptr() -> Self {
        Self {
            tag: -1,
            kind: core::ptr::null_mut(),
        }
    }
}

#[no_mangle]
pub extern "C" fn inflate_WalletType_Mnemonic() -> *mut WalletTypeKind {
    support::new_leak_box_ptr(WalletTypeKind {
        Mnemonic: support::new_leak_box_ptr(wire_WalletType_Mnemonic {
            field0: core::ptr::null_mut(),
        }),
    })
}

#[no_mangle]
pub extern "C" fn inflate_WalletType_PrivateKeys() -> *mut WalletTypeKind {
    support::new_leak_box_ptr(WalletTypeKind {
        PrivateKeys: support::new_leak_box_ptr(wire_WalletType_PrivateKeys {
            field0: core::ptr::null_mut(),
            field1: core::ptr::null_mut(),
        }),
    })
}

#[no_mangle]
pub extern "C" fn inflate_WalletType_ReadOnly() -> *mut WalletTypeKind {
    support::new_leak_box_ptr(WalletTypeKind {
        ReadOnly: support::new_leak_box_ptr(wire_WalletType_ReadOnly {
            field0: core::ptr::null_mut(),
            field1: core::ptr::null_mut(),
        }),
    })
}

// Section: sync execution mode utility

#[no_mangle]
pub extern "C" fn free_WireSyncReturn(ptr: support::WireSyncReturn) {
    unsafe {
        let _ = support::box_from_leak_ptr(ptr);
    };
}
