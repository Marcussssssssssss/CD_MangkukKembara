import 'package:country_state_city/country_state_city.dart'
    show City, getCountryCities;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MaxLengthEnforcement;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../ViewModel/AccountManagement/auth_view_model.dart';
import '../../ViewModel/AccountManagement/profile_view_model.dart';
import '../Widgets/error_state_widget.dart';
import 'change_email_dialog.dart';

/// D6. Edit Profile View.
class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  late final ProfileViewModel _vm;
  final _nameCtrl = TextEditingController();
  final _otherCityCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _country;
  String? _city;
  DateTime? _dateOfBirth;
  String? _gender;
  bool _isOtherCity = false;

  static const _otherCityOption = '__other_city__';
  static const _genderOptions = <String>{
    'male',
    'female',
    'prefer_not_to_say',
  };

  /// ISO 3166-1 alpha-2 countries and territories. The persisted value is
  /// always the code to keep the profile data compact and standardised.
  static final _countries = _CountryOption.fromDelimited(_countryData);
  static const _countryData = '''
AF|Afghanistan
AX|Åland Islands
AL|Albania
DZ|Algeria
AS|American Samoa
AD|Andorra
AO|Angola
AI|Anguilla
AQ|Antarctica
AG|Antigua & Barbuda
AR|Argentina
AM|Armenia
AW|Aruba
AU|Australia
AT|Austria
AZ|Azerbaijan
BS|Bahamas
BH|Bahrain
BD|Bangladesh
BB|Barbados
BY|Belarus
BE|Belgium
BZ|Belize
BJ|Benin
BM|Bermuda
BT|Bhutan
BO|Bolivia
BA|Bosnia & Herzegovina
BW|Botswana
BV|Bouvet Island
BR|Brazil
IO|British Indian Ocean Territory
VG|British Virgin Islands
BN|Brunei
BG|Bulgaria
BF|Burkina Faso
BI|Burundi
KH|Cambodia
CM|Cameroon
CA|Canada
CV|Cape Verde
BQ|Caribbean Netherlands
KY|Cayman Islands
CF|Central African Republic
TD|Chad
CL|Chile
CN|China
CX|Christmas Island
CC|Cocos (Keeling) Islands
CO|Colombia
KM|Comoros
CG|Congo - Brazzaville
CD|Congo - Kinshasa
CK|Cook Islands
CR|Costa Rica
CI|Côte d’Ivoire
HR|Croatia
CU|Cuba
CW|Curaçao
CY|Cyprus
CZ|Czechia
DK|Denmark
DJ|Djibouti
DM|Dominica
DO|Dominican Republic
EC|Ecuador
EG|Egypt
SV|El Salvador
GQ|Equatorial Guinea
ER|Eritrea
EE|Estonia
SZ|Eswatini
ET|Ethiopia
FK|Falkland Islands
FO|Faroe Islands
FJ|Fiji
FI|Finland
FR|France
GF|French Guiana
PF|French Polynesia
TF|French Southern Territories
GA|Gabon
GM|Gambia
GE|Georgia
DE|Germany
GH|Ghana
GI|Gibraltar
GR|Greece
GL|Greenland
GD|Grenada
GP|Guadeloupe
GU|Guam
GT|Guatemala
GG|Guernsey
GN|Guinea
GW|Guinea-Bissau
GY|Guyana
HT|Haiti
HM|Heard & McDonald Islands
HN|Honduras
HK|Hong Kong SAR China
HU|Hungary
IS|Iceland
IN|India
ID|Indonesia
IR|Iran
IQ|Iraq
IE|Ireland
IM|Isle of Man
IL|Israel
IT|Italy
JM|Jamaica
JP|Japan
JE|Jersey
JO|Jordan
KZ|Kazakhstan
KE|Kenya
KI|Kiribati
KW|Kuwait
KG|Kyrgyzstan
LA|Laos
LV|Latvia
LB|Lebanon
LS|Lesotho
LR|Liberia
LY|Libya
LI|Liechtenstein
LT|Lithuania
LU|Luxembourg
MO|Macao SAR China
MG|Madagascar
MW|Malawi
MY|Malaysia
MV|Maldives
ML|Mali
MT|Malta
MH|Marshall Islands
MQ|Martinique
MR|Mauritania
MU|Mauritius
YT|Mayotte
MX|Mexico
FM|Micronesia
MD|Moldova
MC|Monaco
MN|Mongolia
ME|Montenegro
MS|Montserrat
MA|Morocco
MZ|Mozambique
MM|Myanmar (Burma)
NA|Namibia
NR|Nauru
NP|Nepal
NL|Netherlands
NC|New Caledonia
NZ|New Zealand
NI|Nicaragua
NE|Niger
NG|Nigeria
NU|Niue
NF|Norfolk Island
KP|North Korea
MK|North Macedonia
MP|Northern Mariana Islands
NO|Norway
OM|Oman
PK|Pakistan
PW|Palau
PS|Palestinian Territories
PA|Panama
PG|Papua New Guinea
PY|Paraguay
PE|Peru
PH|Philippines
PN|Pitcairn Islands
PL|Poland
PT|Portugal
PR|Puerto Rico
QA|Qatar
RE|Réunion
RO|Romania
RU|Russia
RW|Rwanda
WS|Samoa
SM|San Marino
ST|São Tomé & Príncipe
SA|Saudi Arabia
SN|Senegal
RS|Serbia
SC|Seychelles
SL|Sierra Leone
SG|Singapore
SX|Sint Maarten
SK|Slovakia
SI|Slovenia
SB|Solomon Islands
SO|Somalia
ZA|South Africa
GS|South Georgia & South Sandwich Islands
KR|South Korea
SS|South Sudan
ES|Spain
LK|Sri Lanka
BL|St. Barthélemy
SH|St. Helena
KN|St. Kitts & Nevis
LC|St. Lucia
MF|St. Martin
PM|St. Pierre & Miquelon
VC|St. Vincent & Grenadines
SD|Sudan
SR|Suriname
SJ|Svalbard & Jan Mayen
SE|Sweden
CH|Switzerland
SY|Syria
TW|Taiwan
TJ|Tajikistan
TZ|Tanzania
TH|Thailand
TL|Timor-Leste
TG|Togo
TK|Tokelau
TO|Tonga
TT|Trinidad & Tobago
TN|Tunisia
TR|Turkey
TM|Turkmenistan
TC|Turks & Caicos Islands
TV|Tuvalu
UM|U.S. Outlying Islands
VI|U.S. Virgin Islands
UG|Uganda
UA|Ukraine
AE|United Arab Emirates
GB|United Kingdom
US|United States
UY|Uruguay
UZ|Uzbekistan
VU|Vanuatu
VA|Vatican City
VE|Venezuela
VN|Vietnam
WF|Wallis & Futuna
EH|Western Sahara
YE|Yemen
ZM|Zambia
ZW|Zimbabwe
''';

  @override
  void initState() {
    super.initState();
    _vm = ProfileViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthViewModel>();
      await _reloadProfile(auth);
    });
  }

  Future<void> _reloadProfile(
    AuthViewModel auth, {
    bool showLoading = true,
  }) async {
    if (auth.currentUser == null) return;
    await _vm.loadProfile(auth.currentUser!.id, showLoading: showLoading);
    if (_vm.profile != null) {
      _nameCtrl.text = _vm.profile!.displayName;
      _country = _countries.any((country) => country.code == _vm.profile!.country)
          ? _vm.profile!.country
          : null;
      final savedCity = _vm.profile!.city;
      _city = _country == null ? null : savedCity;
      _isOtherCity = false;
      _otherCityCtrl.clear();
      _dateOfBirth = _vm.profile!.dateOfBirth;
      _gender = _genderOptions.contains(_vm.profile!.gender)
          ? _vm.profile!.gender
          : null;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _otherCityCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await _vm.saveProfile(
      displayName: _nameCtrl.text.trim(),
      country: _country,
      city: _isOtherCity
          ? _otherCityCtrl.text.trim().isEmpty
                ? null
                : _otherCityCtrl.text.trim()
          : _city,
      dateOfBirth: _dateOfBirth,
      gender: _gender,
      avatar: _vm.pendingAvatar,
    );
  }

  Future<void> _changeEmail(AuthViewModel auth) async {
    final currentEmail = auth.currentUser?.email;
    if (currentEmail == null || currentEmail.isEmpty) return;
    final pendingEmail = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ChangeEmailDialog(currentEmail: currentEmail),
    );
    if (pendingEmail == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Verification sent to $pendingEmail. Confirm the new inbox first, then approve the same change from your current inbox.',
        ),
        duration: const Duration(seconds: 20),
      ),
    );
  }

  Future<void> _selectCountry() async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CountryPicker(
        countries: _countries,
        selectedCode: _country,
      ),
    );
    if (code == null || !mounted) return;
    setState(() {
      _country = code;
      _city = null;
      _isOtherCity = false;
      _otherCityCtrl.clear();
    });
  }

  Future<void> _selectCity() async {
    final country = _country;
    if (country == null) return;
    final city = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CityPicker(
        countryCode: country,
        selectedCity: _city,
        otherOption: _otherCityOption,
      ),
    );
    if (city == null || !mounted) return;
    setState(() {
      _isOtherCity = city == _otherCityOption;
      _city = _isOtherCity ? null : city;
      if (!_isOtherCity) _otherCityCtrl.clear();
    });
  }

  Future<void> _choosePhoto(ProfileViewModel vm) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 82,
    );
    if (file != null) vm.setPendingAvatar(file);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _vm,
      child: Consumer2<ProfileViewModel, AuthViewModel>(
        builder: (ctx, vm, auth, _) {
          if (vm.successMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(
                ctx,
              ).showSnackBar(SnackBar(content: Text(vm.successMessage!)));
              Navigator.pop(ctx);
            });
          }
          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Edit Profile'),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      disabledBackgroundColor: AppColors.primaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    onPressed: vm.isSaving ? null : _save,
                    child: vm.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
            body: vm.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : vm.errorMessage != null && vm.profile == null
                ? ErrorStateWidget(
                    message: vm.errorMessage!,
                    onRetry: auth.currentUser == null
                        ? null
                        : () => _reloadProfile(auth),
                  )
                : RefreshIndicator(
                    onRefresh: () => _reloadProfile(auth, showLoading: false),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar
                            Center(
                              child: GestureDetector(
                                onTap: () => _choosePhoto(vm),
                                child: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 44,
                                      backgroundColor: AppColors.accent,
                                      backgroundImage:
                                          vm.pendingAvatar == null &&
                                              vm.profile?.avatarUrl != null
                                          ? NetworkImage(vm.profile!.avatarUrl!)
                                          : null,
                                      child: vm.pendingAvatar != null
                                          ? ClipOval(
                                              child: FutureBuilder(
                                                future: vm.pendingAvatar!
                                                    .readAsBytes(),
                                                builder: (_, snapshot) =>
                                                    snapshot.hasData
                                                    ? Image.memory(
                                                        snapshot.data!,
                                                        width: 88,
                                                        height: 88,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : const CircularProgressIndicator(),
                                              ),
                                            )
                                          : vm.profile?.avatarUrl == null
                                          ? Text(
                                              _nameCtrl.text.isNotEmpty
                                                  ? _nameCtrl.text[0]
                                                        .toUpperCase()
                                                  : '?',
                                              style: const TextStyle(
                                                color: AppColors.textPrimary,
                                                fontWeight: FontWeight.w900,
                                                fontSize: 32,
                                              ),
                                            )
                                          : null,
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        width: 30,
                                        height: 30,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Center(
                              child: Text(
                                'Tap to change photo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            _label('Display Name *'),
                            TextFormField(
                              controller: _nameCtrl,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              maxLength: 50,
                              maxLengthEnforcement:
                                  MaxLengthEnforcement.enforced,
                              decoration: const InputDecoration(
                                hintText: 'Your display name',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                                helperText: '2–50 characters',
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                final name = value?.trim() ?? '';
                                if (name.length < 2 || name.length > 50) {
                                  return 'Display name must be 2–50 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            _label('Email'),
                            InputDecorator(
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.email_outlined),
                                suffixIcon: TextButton(
                                  onPressed: () => _changeEmail(auth),
                                  child: const Text('Change'),
                                ),
                              ),
                              child: Text(auth.currentUser?.email ?? ''),
                            ),
                            if (auth.currentUser?.pendingEmail != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.schedule_send_outlined,
                                    size: 17,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Pending verification: ${auth.currentUser!.pendingEmail}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),

                            _label('Country Code'),
                            InkWell(
                              onTap: _selectCountry,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.flag_outlined),
                                  suffixIcon: Icon(Icons.search_rounded),
                                ),
                                child: Text(
                                  _countries
                                          .where((country) => country.code == _country)
                                          .firstOrNull
                                          ?.label ??
                                      'Select country (optional)',
                                  style: TextStyle(
                                    color: _country == null
                                        ? AppColors.textHint
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            _label('City'),
                            InkWell(
                              onTap: _country == null ? null : _selectCity,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  prefixIcon: const Icon(
                                    Icons.location_city_rounded,
                                  ),
                                  suffixIcon: const Icon(
                                    Icons.search_rounded,
                                  ),
                                  enabled: _country != null,
                                ),
                                child: Text(
                                  _isOtherCity
                                      ? 'Other / Not listed'
                                      : _city ??
                                          (_country == null
                                              ? 'Select a country first'
                                              : 'Select city (optional)'),
                                  style: TextStyle(
                                    color: _country == null
                                        ? AppColors.textHint
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                            if (_isOtherCity) ...[
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _otherCityCtrl,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.location_city_rounded),
                                  hintText: 'Enter your city',
                                ),
                                validator: (value) {
                                  final city = value?.trim() ?? '';
                                  if (city.isEmpty) return 'Enter your city';
                                  if (city.length < 2 || city.length > 80) {
                                    return 'Use 2 to 80 characters';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 16),

                            _label('Date of Birth'),
                            FormField<DateTime>(
                              initialValue: _dateOfBirth,
                              validator: (_) {
                                if (_dateOfBirth == null) return null;
                                final now = DateTime.now();
                                final latest = DateTime(
                                  now.year - 13,
                                  now.month,
                                  now.day,
                                );
                                return _dateOfBirth!.isAfter(latest)
                                    ? 'You must be at least 13 years old'
                                    : null;
                              },
                              builder: (state) => InkWell(
                                onTap: () async {
                                  final now = DateTime.now();
                                  final selected = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(now.year - 120),
                                    lastDate: DateTime(now.year - 13, now.month, now.day),
                                    initialDate: _dateOfBirth ?? DateTime(now.year - 18),
                                  );
                                  if (selected != null && mounted) {
                                    setState(() => _dateOfBirth = selected);
                                    state.didChange(selected);
                                  }
                                },
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    prefixIcon: const Icon(Icons.cake_outlined),
                                    errorText: state.errorText,
                                  ),
                                  child: Text(_dateOfBirth == null
                                      ? 'Select date of birth (optional)'
                                      : DateFormat('d MMMM yyyy').format(_dateOfBirth!)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            _label('Gender'),
                            DropdownButtonFormField<String>(
                              value: _gender,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.person_outline_rounded),
                                hintText: 'Select gender (optional)',
                              ),
                              items: const [
                                DropdownMenuItem(value: 'male', child: Text('Male')),
                                DropdownMenuItem(value: 'female', child: Text('Female')),
                                DropdownMenuItem(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
                              ],
                              onChanged: (value) => setState(() => _gender = value),
                            ),

                            if (vm.errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.errorLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  vm.errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
    ),
  );
}

class _CountryOption {
  const _CountryOption({required this.code, required this.name});

  final String code;
  final String name;

  String get label => '$name - $code';

  static List<_CountryOption> fromDelimited(String data) {
    final countries = data
        .trim()
        .split('\n')
        .map((line) {
          final parts = line.split('|');
          return _CountryOption(code: parts.first, name: parts.last);
        })
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    assert(countries.length == 249, 'Expected all 249 ISO country codes.');
    return countries;
  }
}

class _CountryPicker extends StatefulWidget {
  const _CountryPicker({required this.countries, required this.selectedCode});

  final List<_CountryOption> countries;
  final String? selectedCode;

  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    final matches = widget.countries
        .where(
          (country) =>
              country.name.toLowerCase().contains(query) ||
              country.code.toLowerCase().contains(query),
        )
        .toList();
    final malaysia = widget.countries.firstWhere(
      (country) => country.code == 'MY',
    );
    final showSuggestion = query.isEmpty ||
        malaysia.name.toLowerCase().contains(query) ||
        malaysia.code.toLowerCase().contains(query);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .82,
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Text(
                  'Select country',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search country name or code',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children: [
                    if (showSuggestion) ...[
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
                        child: Text(
                          'Suggested',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _CountryTile(
                        country: malaysia,
                        selected: widget.selectedCode == malaysia.code,
                      ),
                      const Divider(height: 24),
                    ],
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
                      child: Text(
                        'All countries and territories',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (matches.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(28),
                        child: Center(child: Text('No country found.')),
                      )
                    else
                      ...matches.map(
                        (country) => _CountryTile(
                          country: country,
                          selected: widget.selectedCode == country.code,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountryTile extends StatelessWidget {
  const _CountryTile({required this.country, required this.selected});

  final _CountryOption country;
  final bool selected;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(country.name),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(country.code, style: const TextStyle(color: AppColors.textSecondary)),
        if (selected) ...[
          const SizedBox(width: 8),
          const Icon(Icons.check_circle_rounded, color: AppColors.primary),
        ],
      ],
    ),
    onTap: () => Navigator.pop(context, country.code),
  );
}

class _CityPicker extends StatefulWidget {
  const _CityPicker({
    required this.countryCode,
    required this.selectedCity,
    required this.otherOption,
  });

  final String countryCode;
  final String? selectedCity;
  final String otherOption;

  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  final _searchCtrl = TextEditingController();
  late final Future<List<City>> _cities = getCountryCities(widget.countryCode);
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .82,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                'Select city',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Search cities',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<City>>(
                future: _cities,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final cities = (snapshot.data ?? const <City>[])
                      .map((city) => city.name)
                      .toSet()
                      .toList()
                    ..sort();
                  final query = _query.trim().toLowerCase();
                  final matches = cities
                      .where((city) => city.toLowerCase().contains(query))
                      .toList();
                  return ListView(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.edit_location_alt_outlined),
                        title: const Text('Other / Not listed'),
                        onTap: () => Navigator.pop(context, widget.otherOption),
                      ),
                      const Divider(height: 1),
                      if (snapshot.hasError)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'The city list could not be loaded. Choose Other / Not listed to enter your city.',
                          ),
                        )
                      else if (matches.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: Text('No city found.')),
                        )
                      else
                        ...matches.map(
                          (city) => ListTile(
                            title: Text(city),
                            trailing: widget.selectedCity == city
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.primary,
                                  )
                                : null,
                            onTap: () => Navigator.pop(context, city),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
