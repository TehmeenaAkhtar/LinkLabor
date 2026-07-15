import 'package:flutter/material.dart';
import 'verification_screen.dart';
import 'speaker_button.dart';
import 'language_state.dart';

class WorkerRegistrationScreen extends StatefulWidget {
  const WorkerRegistrationScreen({super.key});

  @override
  State<WorkerRegistrationScreen> createState() =>
      _WorkerRegistrationScreenState();
}

class _WorkerRegistrationScreenState extends State<WorkerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cnicController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();

  String? _selectedCity;
  String? _selectedSkill;
  String? _selectedDuration;

  final List<String> _cities = ['Abbottabad', 'Ahmadpur East', 'Arifwala', 'Attock', 'Badin', 'Bahawalnagar', 'Bahawalpur', 'Bannu', 'Batkhela', 'Bhakkar', 'Bhalwal', 'Bhimber', 'Burewala', 'Chakwal', 'Chaman', 'Charsadda', 'Chichawatni', 'Chiniot', 'Chishtian', 'Dadu', 'Daska', 'Dera Ghazi Khan', 'Dera Ismail Khan', 'Faisalabad', 'Ghotki', 'Gilgit', 'Gojra', 'Gujranwala', 'Gujrat', 'Gwadar', 'Hafizabad', 'Haripur', 'Hyderabad', 'Islamabad', 'Jacobabad', 'Jaranwala', 'Jhang', 'Jhelum', 'Kamalia', 'Kamoke', 'Karachi', 'Kasur', 'Khairpur', 'Khanewal', 'Khanpur', 'Khushab', 'Kohat', 'Kot Addu', 'Lahore', 'Larkana', 'Layyah', 'Lodhran', 'Mandi Bahauddin', 'Mansehra', 'Mardan', 'Mianwali', 'Mingora', 'Mirpur', 'Mirpur Khas', 'Multan', 'Muzaffarabad', 'Murree', 'Nankana Sahib', 'Narowal', 'Nawabshah', 'Nowshera', 'Okara', 'Pakpattan', 'Peshawar', 'Quetta', 'Rahim Yar Khan', 'Rawalpindi', 'Sadiqabad', 'Sahiwal', 'Sargodha', 'Sheikhupura', 'Shikarpur', 'Sialkot', 'Sibi', 'Skardu', 'Sukkur', 'Swabi', 'Taxila', 'Toba Tek Singh', 'Turbat', 'Vehari', 'Wah Cantonment', 'Zhob'];
  final List<String> _skills = ['AC Technician', 'Blacksmith', 'Bricklayer', 'Bus Conductor', 'Butcher', 'Cable Installer', 'Car Mechanic', 'Car Painter', 'Carpenter', 'Cement Mason', 'Cleaner', 'Construction Worker', 'Cook', 'Crane Operator', 'Delivery Rider', 'Driver', 'Drywall Installer', 'Electrician', 'Factory Worker', 'Farmer', 'Gardener', 'Glass Installer', 'Helper', 'House Painter', 'HVAC Technician', 'Iron Worker', 'Janitor', 'Laborer', 'Landscaper', 'Loader', 'Locksmith', 'Machine Operator', 'Maid', 'Mason', 'Mechanic', 'Miner', 'Office Boy', 'Painter', 'Pest Control Worker', 'Pipe Fitter', 'Plasterer', 'Plumber', 'Porter', 'Road Worker', 'Roofing Worker', 'Sanitary Worker', 'Scaffolder', 'Security Guard', 'Sewing Machine Operator', 'Steel Fixer', 'Store Keeper', 'Surveyor', 'Tailor', 'Taxi Driver', 'Technician', 'Tile Setter', 'Truck Driver', 'Turner', 'Upholsterer', 'Waiter', 'Warehouse Worker', 'Welder', 'Wood Polisher'];
  final List<String> _durations = ['1-3 Hours', '4-6 Hours', 'Full Day'];

  // ── Urdu translations (display-only; stored value stays English) ──
  final Map<String, String> _cityUrdu = {
    'Abbottabad': 'ایبٹ آباد', 'Ahmadpur East': 'احمد پور شرقیہ', 'Arifwala': 'عارف والا',
    'Attock': 'اٹک', 'Badin': 'بدین', 'Bahawalnagar': 'بہاولنگر', 'Bahawalpur': 'بہاولپور',
    'Bannu': 'بنوں', 'Batkhela': 'بٹ خیلہ', 'Bhakkar': 'بھکر', 'Bhalwal': 'بھلوال',
    'Bhimber': 'بھمبر', 'Burewala': 'بورے والا', 'Chakwal': 'چکوال', 'Chaman': 'چمن',
    'Charsadda': 'چارسدہ', 'Chichawatni': 'چیچہ وطنی', 'Chiniot': 'چنیوٹ', 'Chishtian': 'چشتیاں',
    'Dadu': 'دادو', 'Daska': 'ڈسکہ', 'Dera Ghazi Khan': 'ڈیرہ غازی خان',
    'Dera Ismail Khan': 'ڈیرہ اسماعیل خان', 'Faisalabad': 'فیصل آباد', 'Ghotki': 'گھوٹکی',
    'Gilgit': 'گلگت', 'Gojra': 'گوجرہ', 'Gujranwala': 'گوجرانوالہ', 'Gujrat': 'گجرات',
    'Gwadar': 'گوادر', 'Hafizabad': 'حافظ آباد', 'Haripur': 'ہری پور', 'Hyderabad': 'حیدرآباد',
    'Islamabad': 'اسلام آباد', 'Jacobabad': 'جیکب آباد', 'Jaranwala': 'جڑانوالہ', 'Jhang': 'جھنگ',
    'Jhelum': 'جہلم', 'Kamalia': 'کمالیہ', 'Kamoke': 'کامونکے', 'Karachi': 'کراچی',
    'Kasur': 'قصور', 'Khairpur': 'خیرپور', 'Khanewal': 'خانیوال', 'Khanpur': 'خانپور',
    'Khushab': 'خوشاب', 'Kohat': 'کوہاٹ', 'Kot Addu': 'کوٹ ادو', 'Lahore': 'لاہور',
    'Larkana': 'لاڑکانہ', 'Layyah': 'لیہ', 'Lodhran': 'لودھراں',
    'Mandi Bahauddin': 'منڈی بہاؤالدین', 'Mansehra': 'مانسہرہ', 'Mardan': 'مردان',
    'Mianwali': 'میانوالی', 'Mingora': 'مینگورہ', 'Mirpur': 'میرپور', 'Mirpur Khas': 'میرپورخاص',
    'Multan': 'ملتان', 'Muzaffarabad': 'مظفرآباد', 'Murree': 'مری',
    'Nankana Sahib': 'ننکانہ صاحب', 'Narowal': 'نارووال', 'Nawabshah': 'نوابشاہ',
    'Nowshera': 'نوشہرہ', 'Okara': 'اوکاڑہ', 'Pakpattan': 'پاکپتن', 'Peshawar': 'پشاور',
    'Quetta': 'کوئٹہ', 'Rahim Yar Khan': 'رحیم یار خان', 'Rawalpindi': 'راولپنڈی',
    'Sadiqabad': 'صادق آباد', 'Sahiwal': 'ساہیوال', 'Sargodha': 'سرگودھا',
    'Sheikhupura': 'شیخوپورہ', 'Shikarpur': 'شکارپور', 'Sialkot': 'سیالکوٹ', 'Sibi': 'سبی',
    'Skardu': 'سکردو', 'Sukkur': 'سکھر', 'Swabi': 'سوابی', 'Taxila': 'ٹیکسلا',
    'Toba Tek Singh': 'ٹوبہ ٹیک سنگھ', 'Turbat': 'تربت', 'Vehari': 'وہاڑی',
    'Wah Cantonment': 'واہ کینٹ', 'Zhob': 'ژوب',
  };

  final Map<String, String> _skillUrdu = {
    'AC Technician': 'اے سی ٹیکنیشن', 'Blacksmith': 'لوہار', 'Bricklayer': 'راج مستری',
    'Bus Conductor': 'بس کنڈکٹر', 'Butcher': 'قصاب', 'Cable Installer': 'کیبل انسٹالر',
    'Car Mechanic': 'کار مکینک', 'Car Painter': 'کار پینٹر', 'Carpenter': 'بڑھئی',
    'Cement Mason': 'سیمنٹ مستری', 'Cleaner': 'صفائی کرنے والا',
    'Construction Worker': 'تعمیراتی مزدور', 'Cook': 'باورچی', 'Crane Operator': 'کرین آپریٹر',
    'Delivery Rider': 'ڈیلیوری رائیڈر', 'Driver': 'ڈرائیور',
    'Drywall Installer': 'ڈرائی وال انسٹالر', 'Electrician': 'الیکٹریشن',
    'Factory Worker': 'فیکٹری ورکر', 'Farmer': 'کسان', 'Gardener': 'مالی',
    'Glass Installer': 'شیشہ فٹر', 'Helper': 'مددگار', 'House Painter': 'گھر کا پینٹر',
    'HVAC Technician': 'ایچ وی اے سی ٹیکنیشن', 'Iron Worker': 'آئرن ورکر',
    'Janitor': 'صفائی ملازم', 'Laborer': 'مزدور', 'Landscaper': 'لینڈ سکیپر',
    'Loader': 'لوڈر', 'Locksmith': 'تالا ساز', 'Machine Operator': 'مشین آپریٹر',
    'Maid': 'گھریلو ملازمہ', 'Mason': 'مستری', 'Mechanic': 'مکینک', 'Miner': 'کان کن',
    'Office Boy': 'آفس بوائے', 'Painter': 'پینٹر',
    'Pest Control Worker': 'پیسٹ کنٹرول ورکر', 'Pipe Fitter': 'پائپ فٹر',
    'Plasterer': 'پلستر کار', 'Plumber': 'پلمبر', 'Porter': 'قلی',
    'Road Worker': 'سڑک مزدور', 'Roofing Worker': 'چھت ساز',
    'Sanitary Worker': 'سینیٹری ورکر', 'Scaffolder': 'اسکافولڈر',
    'Security Guard': 'سیکیورٹی گارڈ', 'Sewing Machine Operator': 'سلائی مشین آپریٹر',
    'Steel Fixer': 'اسٹیل فکسر', 'Store Keeper': 'اسٹور کیپر', 'Surveyor': 'سرویئر',
    'Tailor': 'درزی', 'Taxi Driver': 'ٹیکسی ڈرائیور', 'Technician': 'ٹیکنیشن',
    'Tile Setter': 'ٹائل سیٹر', 'Truck Driver': 'ٹرک ڈرائیور', 'Turner': 'ٹرنر',
    'Upholsterer': 'اپہولسٹرر', 'Waiter': 'ویٹر', 'Warehouse Worker': 'گودام کا ورکر',
    'Welder': 'ویلڈر', 'Wood Polisher': 'لکڑی پالش کرنے والا',
  };

  final Map<String, String> _durationUrdu = {
    '1-3 Hours': '1-3 گھنٹے',
    '4-6 Hours': '4-6 گھنٹے',
    'Full Day': 'پورا دن',
  };

  void _handleNext() {
    if (_formKey.currentState!.validate()) {
      final Map<String, String> workerData = {
        'fullName': _nameController.text.trim(),
        'cnic': _cnicController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _selectedCity ?? '',
        'skill': _selectedSkill ?? '',
        'availableHours': _selectedDuration ?? '',
        'about': _aboutController.text.trim(),
      };
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationScreen(workerData: workerData),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(25),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        isUrdu ? "اپنا پروفائل بنائیں" : "Create your Profile",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E8449),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Center(
                      child: Text(
                        isUrdu ? "( بطور کارکن )" : "( As a Worker )",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF17A589),
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // ── Full Name ──
                    _buildLabel(
                      "Enter your full name",
                      "اپنا پورا نام درج کریں",
                    ),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                        isUrdu ? "مثلاً محمد علی" : "e.g. Muhammad Ali",
                      ),
                      validator: (v) =>
                      v == null || v.isEmpty
                          ? (isUrdu ? "نام درج کریں" : "Enter name")
                          : null,
                    ),

                    // ── CNIC ──
                    _buildLabel(
                      "Enter CNIC",
                      "اپنا شناختی کارڈ نمبر درج کریں",
                    ),
                    TextFormField(
                      controller: _cnicController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        isUrdu ? "مثلاً 3720152676988" : "e.g. 3720152676988",
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return isUrdu ? "شناختی کارڈ نمبر درج کریں" : "Enter CNIC";
                        }
                        if (v.length < 13) {
                          return isUrdu ? "غلط شناختی کارڈ نمبر" : "Invalid CNIC";
                        }
                        return null;
                      },
                    ),

                    // ── Phone ──
                    _buildLabel(
                      "Enter Phone no.",
                      "اپنا فون نمبر درج کریں",
                    ),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        isUrdu ? "مثلاً 03332343654" : "e.g. 03332343654",
                      ),
                      validator: (v) =>
                      v == null || v.isEmpty
                          ? (isUrdu ? "فون نمبر درج کریں" : "Enter phone number")
                          : null,
                    ),

                    // ── City ──
                    _buildLabel(
                      "Select City",
                      "اپنا شہر منتخب کریں",
                    ),
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration(
                        isUrdu ? "شہر" : "City",
                      ),
                      initialValue: _selectedCity,
                      items: _cities
                          .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(isUrdu ? (_cityUrdu[c] ?? c) : c),
                      ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedCity = v),
                      validator: (v) => v == null
                          ? (isUrdu ? "شہر منتخب کریں" : "Select a city")
                          : null,
                    ),

                    // ── Skill ──
                    _buildLabel(
                      "Select Skill",
                      "اپنی مہارت منتخب کریں",
                    ),
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration(
                        isUrdu ? "مہارت" : "Skill",
                      ),
                      initialValue: _selectedSkill,
                      items: _skills
                          .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(isUrdu ? (_skillUrdu[s] ?? s) : s),
                      ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedSkill = v),
                      validator: (v) => v == null
                          ? (isUrdu ? "مہارت منتخب کریں" : "Select a skill")
                          : null,
                    ),

                    // ── Availability ──
                    _buildLabel(
                      "Daily Availability",
                      "روزانہ دستیابی منتخب کریں",
                    ),
                    DropdownButtonFormField<String>(
                      decoration: _inputDecoration(
                        isUrdu ? "دورانیہ" : "Duration",
                      ),
                      initialValue: _selectedDuration,
                      items: _durations
                          .map((d) => DropdownMenuItem(
                        value: d,
                        child: Text(isUrdu ? (_durationUrdu[d] ?? d) : d),
                      ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedDuration = v),
                      validator: (v) => v == null
                          ? (isUrdu ? "دورانیہ منتخب کریں" : "Select duration")
                          : null,
                    ),

                    // ── About ──
                    _buildLabel(
                      "About (Optional)",
                      "اپنے بارے میں لکھیں، یہ ضروری نہیں ہے",
                    ),
                    TextFormField(
                      controller: _aboutController,
                      decoration: _inputDecoration(
                        isUrdu
                            ? "اپنے تجربے کے بارے میں لکھیں..."
                            : "Tell us about your experience...",
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 30),

                    ElevatedButton(
                      onPressed: _handleNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E8449),
                        padding:
                        const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isUrdu ? "اگلا" : "Next",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Label with speaker icon ──
  Widget _buildLabel(String text, String urduText) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isUrdu ? urduText : text,   // ← now switches with language
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 6),
          SpeakerButton(urduText: urduText),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding:
      const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1E8449), width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}