/**
 * i18n.js — Shop Credit Manager
 * English / Marathi bilingual support
 * Reads/writes language preference from localStorage key: 'scm_lang'
 */
(function () {
  'use strict';

  var TRANSLATIONS = {

    // ══════════════════════════ ENGLISH ══════════════════════════
    en: {
      /* ─── Navigation ─── */
      'nav.dashboard':     'Dashboard',
      'nav.add_customer':  'Add Customer',
      'nav.customers':     'Customers',
      'nav.add_dealer':    'Add Dealer',
      'nav.dealers':       'Dealers',
      'nav.products':      'Products',
      'nav.requests':      'Requests',
      'nav.sign_out':      'Sign Out',
	  'nav.cash':          'Cash Sale',

      /* ─── Logout modal ─── */
      'logout.title':   'Sign Out?',
      'logout.msg':     "You'll need to sign in again to access the system.",
      'logout.cancel':  'Cancel',
      'logout.confirm': 'Yes, Sign Out',

      /* ─── Dashboard ─── */
      'dash.quick_actions':      'Quick Actions',
      'dash.total_customers':    'Customers',
      'dash.customer_credit':    'Customer Credit',
      'dash.total_dealers':      'Dealers',
      'dash.dealer_credit':      'Dealer Credit',
      'dash.total_products':     'Products',
      'dash.add_customer':       'Add Customer',
      'dash.add_customer_desc':  'Register a new customer with credit account',
      'dash.customers':          'Customers',
      'dash.customers_desc':     'Manage credit & transactions',
      'dash.add_dealer':         'Add Dealer',
      'dash.add_dealer_desc':    'Register a new dealer supplier',
      'dash.dealers':            'Dealers',
      'dash.dealers_desc':       'Manage dealer credit & stock',
      'dash.products':           'Products',
      'dash.products_desc':      'View & manage stock inventory',

      /* ─── Common buttons ─── */
      'btn.save':           'Save',
      'btn.cancel':         'Cancel',
      'btn.search':         'Search',
      'btn.reset':          'Reset',
      'btn.add_credit':     '➕ Add Credit',
      'btn.settle':         '✅ Settle',
      'btn.view':           '📄 View',
      'btn.delete':         '🗑 Delete',
      'btn.print':          '🖨️ Print Statement',
      'btn.back_customers': '← Back to Customers',
      'btn.back_dealers':   '← Back to Dealers',
      'btn.back_list':      '← Back',

      /* ─── Customer form ─── */
      'cust.legend':           'Customer Details',
      'cust.name':             'Full Name',
      'cust.name_ph':          "Enter customer's full name",
      'cust.marathi_name':     'Name in Marathi (Optional)',
      'cust.marathi_name_ph':  'मराठीत नाव टाका',
      'cust.phone':            'Phone Number',
      'cust.phone_ph':         '10-digit mobile number',
      'cust.address':          'Address',
      'cust.address_ph':       'Street, area, city…',
      'cust.credit':           'Opening Credit Balance (₹)',
      'cust.save':             '💾 Save Customer',
      'cust.clear':            '🔄 Clear',

      /* ─── Dealer form ─── */
      'dealer.legend':          'Dealer Information',
      'dealer.name':            'Dealer / Company Name',
      'dealer.name_ph':         'Enter dealer or company name',
      'dealer.marathi_name':    'Name in Marathi (Optional)',
      'dealer.marathi_name_ph': 'मराठीत नाव टाका',
      'dealer.phone':           'Phone Number',
      'dealer.phone_ph':        '10-digit mobile number',
      'dealer.address':         'Address',
      'dealer.address_ph':      'Enter full address (street, area, city...)',
      'dealer.credit':          'Initial Credit Amount (₹)',
      'dealer.save':            '💾 Save Dealer',
      'dealer.clear':           '🔄 Clear',

      /* ─── View customers ─── */
      'vc.search_ph': '🔍 Search by Name, Phone or ID',
      'vc.th_id':     'ID',
      'vc.th_name':   'Name',
      'vc.th_phone':  'Phone',
      'vc.th_credit': 'Credit (₹)',
      'vc.th_actions':'Actions',
      'vc.th_details':'Details',
      'vc.no_data':   '⚠ No customers found.',

      /* ─── View dealers ─── */
      'vd.search_ph': '🔍 Search by Name, Phone or ID',
      'vd.th_id':     'ID',
      'vd.th_name':   'Dealer Name',
      'vd.th_phone':  'Phone',
      'vd.th_credit': 'Total Credit (₹)',
      'vd.th_actions':'Actions',
      'vd.th_details':'Details',
      'vd.no_data':   '⚠ No dealers found.',

      /* ─── Products ─── */
      'prod.new_label':    'New Product',
      'prod.name_label':   'Product Name',
      'prod.name_ph':      'Enter product name',
      'prod.mr_name_label':'Marathi Name (Optional)',
      'prod.mr_name_ph':   'मराठीत उत्पाद नाव',
      'prod.stock_label':  'Initial Stock',
      'prod.add_btn':      '💾 Add Product',
      'prod.search_ph':    'Search by product name or ID…',
      'prod.th_sr':        'Sr.No',
      'prod.th_id':        'Product ID',
      'prod.th_name':      'Product Name',
      'prod.th_stock':     'Stock Status',
      'prod.th_remove':    'Remove',
      'prod.stat_total':   'Total Products',
      'prod.stat_in':      'In Stock',
      'prod.stat_low':     'Low Stock',
      'prod.stat_out':     'Out of Stock',

      /* ─── Add credit ─── */
      'ac.panel_hdr':    '➕ Add Product',
      'ac.table_hdr':    '🧾 Transaction Items',
      'ac.lbl_product':  '📦 Product',
      'ac.lbl_qty':      '🔢 Quantity',
      'ac.lbl_price':    '💰 Price / Unit (₹)',
      'ac.lbl_total':    'Total (₹)',
      'ac.btn_add':      '➕ Add to Table',
      'ac.btn_save':     '💾 Save Credit Transaction',
      'ac.credit_label': 'TOTAL CREDIT TO ADD',
      'ac.th_no':        '#',
      'ac.th_product':   'Product',
      'ac.th_qty':       'Qty',
      'ac.th_price':     'Price / Unit (₹)',
      'ac.th_total':     'Total (₹)',
      'ac.th_grand':     'Grand Total',

      /* ─── Settle ─── */
      'set.legend':    'Settlement Details',
      'set.amount':    'Settlement Amount (₹)',
      'set.pay_mode':  'Payment Mode',
      'set.cash':      'Cash',
      'set.online':    'Online Transfer',
      'set.confirm':   '✅ Confirm Settlement',
      'set.outstanding':'Outstanding Credit',
      'set.no_credit': 'No outstanding credit.',

      /* ─── Details page ─── */
      'det.th_no':      '#',
      'det.th_txn_id':  'Txn ID',
      'det.th_date':    'Date',
      'det.th_type':    'Type',
      'det.th_product': 'Product / Item',
      'det.th_qty':     'Quantity',
      'det.th_pay':     'Payment Mode',
      'det.th_amount':  'Amount (₹)',
      'det.print_from': 'From:',
      'det.print_to':   'To:',
      'det.print_range':'🖨️ Print Selected Range',
      'det.print_all':  'Print All Transactions',
      'det.txn_history':'📊 Transaction History',
      'det.no_txn':     'No transactions found.',

      /* ─── Requests page ─── */
      'req.title':           'Requests',
      'req.subtitle':        'Generate and share product or cash requests with Dealers and Customers.',
      'req.product_card':    'Product Request',
      'req.product_desc':    'Request specific products from a dealer',
      'req.cash_card':       'Cash Request',
      'req.cash_desc':       'Generate a payment reminder message',
      'req.dealer_lbl':      '🏬 Dealer:',
      'req.sel_product_hdr': '➕ Add Product to Request',
      'req.items_hdr':       '🧾 Request Items',
      'req.product_lbl':     '📦 Product',
      'req.qty_lbl':         '🔢 Quantity',
      'req.add_btn':         '➕ Add to Request',
      'req.gen_btn':         '📩 Generate Message',
      'req.customer_hdr':    '👤 Select Customer',
      'req.customer_lbl':    '👤 Customer Name',
      'req.th_no':           '#',
      'req.th_product':      'Product Name',
      'req.th_qty':          'Quantity',
    },

    // ══════════════════════════ MARATHI ══════════════════════════
    mr: {
      /* ─── Navigation ─── */
      'nav.dashboard':     'डॅशबोर्ड',
      'nav.add_customer':  'ग्राहक जोडा',
      'nav.customers':     'ग्राहक',
      'nav.add_dealer':    'डीलर जोडा',
      'nav.dealers':       'डीलर',
      'nav.products':      'उत्पादने',
      'nav.requests':      'विनंत्या',
      'nav.sign_out':      'बाहेर पडा',
	  'nav.cash':		   'रोख विक्री',

      /* ─── Logout modal ─── */
      'logout.title':   'बाहेर पडायचे?',
      'logout.msg':     'प्रणालीत प्रवेश करण्यासाठी पुन्हा साइन इन करावे लागेल.',
      'logout.cancel':  'रद्द करा',
      'logout.confirm': 'होय, बाहेर पडा',

      /* ─── Dashboard ─── */
      'dash.quick_actions':      'त्वरित क्रिया',
      'dash.total_customers':    'ग्राहक',
      'dash.customer_credit':    'ग्राहक उधार',
      'dash.total_dealers':      'डीलर',
      'dash.dealer_credit':      'डीलर उधार',
      'dash.total_products':     'उत्पादने',
      'dash.add_customer':       'ग्राहक जोडा',
      'dash.add_customer_desc':  'नवीन ग्राहक नोंदवा',
      'dash.customers':          'ग्राहक',
      'dash.customers_desc':     'उधार आणि व्यवहार व्यवस्थापन',
      'dash.add_dealer':         'डीलर जोडा',
      'dash.add_dealer_desc':    'नवीन डीलर पुरवठादार नोंदवा',
      'dash.dealers':            'डीलर',
      'dash.dealers_desc':       'डीलर उधार आणि स्टॉक व्यवस्थापन',
      'dash.products':           'उत्पादने',
      'dash.products_desc':      'स्टॉक यादी पहा व व्यवस्थापित करा',

      /* ─── Common buttons ─── */
      'btn.save':           'जतन करा',
      'btn.cancel':         'रद्द करा',
      'btn.search':         'शोधा',
      'btn.reset':          'रीसेट',
      'btn.add_credit':     '➕ उधार जोडा',
      'btn.settle':         '✅ परतफेड',
      'btn.view':           '📄 पहा',
      'btn.delete':         '🗑 हटवा',
      'btn.print':          '🖨️ विवरण छापा',
      'btn.back_customers': '← ग्राहकांकडे परत',
      'btn.back_dealers':   '← डीलरकडे परत',
      'btn.back_list':      '← परत',

      /* ─── Customer form ─── */
      'cust.legend':           'ग्राहक तपशील',
      'cust.name':             'पूर्ण नाव',
      'cust.name_ph':          'ग्राहकाचे पूर्ण नाव टाका',
      'cust.marathi_name':     'मराठीत नाव',
      'cust.marathi_name_ph':  'मराठीत नाव टाका',
      'cust.phone':            'दूरध्वनी क्रमांक',
      'cust.phone_ph':         '१०-अंकी मोबाइल क्रमांक',
      'cust.address':          'पत्ता',
      'cust.address_ph':       'रस्ता, परिसर, शहर...',
      'cust.credit':           'प्रारंभिक उधार शिल्लक (₹)',
      'cust.save':             '💾 ग्राहक जतन करा',
      'cust.clear':            '🔄 साफ करा',

      /* ─── Dealer form ─── */
      'dealer.legend':          'डीलर माहिती',
      'dealer.name':            'डीलर / कंपनी नाव',
      'dealer.name_ph':         'डीलर किंवा कंपनीचे नाव टाका',
      'dealer.marathi_name':    'मराठीत नाव',
      'dealer.marathi_name_ph': 'मराठीत नाव टाका',
      'dealer.phone':           'दूरध्वनी क्रमांक',
      'dealer.phone_ph':        '१०-अंकी मोबाइल क्रमांक',
      'dealer.address':         'पत्ता',
      'dealer.address_ph':      'संपूर्ण पत्ता टाका',
      'dealer.credit':          'प्रारंभिक उधार रक्कम (₹)',
      'dealer.save':            '💾 डीलर जतन करा',
      'dealer.clear':           '🔄 साफ करा',

      /* ─── View customers ─── */
      'vc.search_ph': '🔍 नाव, दूरध्वनी किंवा क्र. ने शोधा',
      'vc.th_id':     'क्र.',
      'vc.th_name':   'नाव',
      'vc.th_phone':  'दूरध्वनी',
      'vc.th_credit': 'उधार (₹)',
      'vc.th_actions':'क्रिया',
      'vc.th_details':'तपशील',
      'vc.no_data':   '⚠ कोणताही ग्राहक सापडला नाही.',

      /* ─── View dealers ─── */
      'vd.search_ph': '🔍 नाव, दूरध्वनी किंवा क्र. ने शोधा',
      'vd.th_id':     'क्र.',
      'vd.th_name':   'डीलरचे नाव',
      'vd.th_phone':  'दूरध्वनी',
      'vd.th_credit': 'एकूण उधार (₹)',
      'vd.th_actions':'क्रिया',
      'vd.th_details':'तपशील',
      'vd.no_data':   '⚠ कोणताही डीलर सापडला नाही.',

      /* ─── Products ─── */
      'prod.new_label':    'नवीन उत्पाद',
      'prod.name_label':   'उत्पादाचे नाव',
      'prod.name_ph':      'उत्पादाचे नाव टाका',
      'prod.mr_name_label':'मराठीत नाव (ऐच्छिक)',
      'prod.mr_name_ph':   'मराठीत उत्पाद नाव',
      'prod.stock_label':  'प्रारंभिक स्टॉक',
      'prod.add_btn':      '💾 उत्पाद जोडा',
      'prod.search_ph':    'उत्पाद नाव किंवा क्र. ने शोधा…',
      'prod.th_sr':        'अ.क्र.',
      'prod.th_id':        'उत्पाद क्र.',
      'prod.th_name':      'उत्पादाचे नाव',
      'prod.th_stock':     'स्टॉक स्थिती',
      'prod.th_remove':    'हटवा',
      'prod.stat_total':   'एकूण उत्पादे',
      'prod.stat_in':      'स्टॉकमध्ये',
      'prod.stat_low':     'कमी स्टॉक',
      'prod.stat_out':     'स्टॉक संपला',

      /* ─── Add credit ─── */
      'ac.panel_hdr':    '➕ उत्पाद जोडा',
      'ac.table_hdr':    '🧾 व्यवहार यादी',
      'ac.lbl_product':  '📦 उत्पाद',
      'ac.lbl_qty':      '🔢 प्रमाण',
      'ac.lbl_price':    '💰 किंमत / नग (₹)',
      'ac.lbl_total':    'एकूण (₹)',
      'ac.btn_add':      '➕ यादीत जोडा',
      'ac.btn_save':     '💾 उधार व्यवहार जतन करा',
      'ac.credit_label': 'जोडायची एकूण उधार',
      'ac.th_no':        '#',
      'ac.th_product':   'उत्पाद',
      'ac.th_qty':       'प्रमाण',
      'ac.th_price':     'किंमत / नग (₹)',
      'ac.th_total':     'एकूण (₹)',
      'ac.th_grand':     'एकूण',

      /* ─── Settle ─── */
      'set.legend':    'परतफेड तपशील',
      'set.amount':    'परतफेड रक्कम (₹)',
      'set.pay_mode':  'देयक पद्धत',
      'set.cash':      'रोख',
      'set.online':    'ऑनलाइन हस्तांतरण',
      'set.confirm':   '✅ परतफेड पक्की करा',
      'set.outstanding':'थकबाकी उधार',
      'set.no_credit': 'थकबाकी नाही.',

      /* ─── Details page ─── */
      'det.th_no':      '#',
      'det.th_txn_id':  'व्यवहार क्र.',
      'det.th_date':    'दिनांक',
      'det.th_type':    'प्रकार',
      'det.th_product': 'उत्पाद / वस्तू',
      'det.th_qty':     'प्रमाण',
      'det.th_pay':     'देयक पद्धत',
      'det.th_amount':  'रक्कम (₹)',
      'det.print_from': 'पासून:',
      'det.print_to':   'पर्यंत:',
      'det.print_range':'🖨️ निवडलेली श्रेणी छापा',
      'det.print_all':  'सर्व व्यवहार छापा',
      'det.txn_history':'📊 व्यवहार इतिहास',
      'det.no_txn':     'कोणताही व्यवहार सापडला नाही.',

      /* ─── Requests page ─── */
      'req.title':           'विनंत्या',
      'req.subtitle':        'डीलर आणि ग्राहकांसोबत उत्पाद किंवा रोख विनंती तयार करा आणि शेअर करा.',
      'req.product_card':    'उत्पाद विनंती',
      'req.product_desc':    'डीलरकडून विशिष्ट उत्पादे मागवा',
      'req.cash_card':       'रोख विनंती',
      'req.cash_desc':       'देयक स्मरणपत्र संदेश तयार करा',
      'req.dealer_lbl':      '🏬 डीलर:',
      'req.sel_product_hdr': '➕ विनंतीत उत्पाद जोडा',
      'req.items_hdr':       '🧾 विनंती यादी',
      'req.product_lbl':     '📦 उत्पाद',
      'req.qty_lbl':         '🔢 प्रमाण',
      'req.add_btn':         '➕ विनंतीत जोडा',
      'req.gen_btn':         '📩 संदेश तयार करा',
      'req.customer_hdr':    '👤 ग्राहक निवडा',
      'req.customer_lbl':    '👤 ग्राहकाचे नाव',
      'req.th_no':           '#',
      'req.th_product':      'उत्पादाचे नाव',
      'req.th_qty':          'प्रमाण',
    }
  };

  // ── Core API ───────────────────────────────────────────────────────────
  var _lang = localStorage.getItem('scm_lang') || 'en';

  function t(key) {
    var dict = TRANSLATIONS[_lang] || TRANSLATIONS.en;
    return dict[key] !== undefined ? dict[key] : (TRANSLATIONS.en[key] || key);
  }

  function getLang() { return _lang; }

  function setLang(lang) {
    _lang = lang;
    localStorage.setItem('scm_lang', lang);
  }

  /**
   * Apply translations to the current document.
   * Elements use:
   *   data-i18n="key"          → sets textContent
   *   data-i18n-ph="key"       → sets placeholder
   *   data-i18n-html="key"     → sets innerHTML (use sparingly)
   * Language-specific visibility:
   *   .lang-name-en / .lang-name-mr  → show/hide by language
   */
  function applyTranslations() {
    /* Text content */
    document.querySelectorAll('[data-i18n]').forEach(function (el) {
      el.textContent = t(el.getAttribute('data-i18n'));
    });

    /* Placeholders */
    document.querySelectorAll('[data-i18n-ph]').forEach(function (el) {
      el.placeholder = t(el.getAttribute('data-i18n-ph'));
    });

    /* innerHTML (for rich text e.g. with ₹ HTML entity) */
    document.querySelectorAll('[data-i18n-html]').forEach(function (el) {
      el.innerHTML = t(el.getAttribute('data-i18n-html'));
    });

    /* Language-conditional name display */
    var isMr = (_lang === 'mr');
    document.querySelectorAll('.lang-name-en').forEach(function (el) {
      el.style.display = isMr ? 'none' : '';
    });
    document.querySelectorAll('.lang-name-mr').forEach(function (el) {
      el.style.display = isMr ? '' : 'none';
    });

    /* Set html lang attribute */
    document.documentElement.lang = _lang === 'mr' ? 'mr' : 'en';
  }

  /* Auto-apply when DOM is ready */
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', applyTranslations);
  } else {
    applyTranslations();
  }

  /* Public API */
  window.i18n = { t: t, getLang: getLang, setLang: setLang, apply: applyTranslations };
})();
