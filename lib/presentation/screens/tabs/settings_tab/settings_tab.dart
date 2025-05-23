import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:news_lens/l10n/l10n_extension.dart';
import 'package:news_lens/presentation/screens/onboarding/pre_settings/pre_settings_provider.dart';
import 'package:news_lens/providers/locale_provider.dart';
import 'package:news_lens/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late PreSettingsProvider _preSettingsProvider;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _preSettingsProvider = Provider.of<PreSettingsProvider>(context, listen: false);
    _preSettingsProvider.getUserInfo(); // Carica le informazioni dell'utente
    _preSettingsProvider.updateInterests([
    'politics',
    'sports', 
    'science',
    'technology',
    'business',
    'health'
  ],false);
  }

  // Widget per costruire l'immagine del profilo
  Widget _buildProfileImage(PreSettingsProvider provider) {
    if (provider.hasProfileImage()) {
      return ClipOval(
        child: Image.file(
          provider.getCurrentImage()!,
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Icon(
        Icons.camera_alt,
        size: 50,
        color: Theme.of(context).colorScheme.primary,
      );
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushNamedAndRemoveUntil(
          context, "/", (Route<dynamic> route) => false);
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error signing out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l10n.settings),
        actions: [
          GestureDetector(
            onTap: _logout,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Icon(
                Icons.logout, 
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<PreSettingsProvider>(
          builder: (context, preSettings, _) {
            if (!preSettings.dataLoaded) {
              return const Center(child: CircularProgressIndicator());
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                GestureDetector(
                  onTap: () => preSettings.getImage(context),
                  onLongPress: () => preSettings.removeImage(),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    child: _buildProfileImage(preSettings),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      preSettings.nickname.isNotEmpty
                          ? preSettings.nickname
                          : 'Default Nickname',
                      style: const TextStyle(fontSize: 16),
                    ),
                    IconButton(
                      onPressed: _editNickname,
                      icon: Icon(Icons.edit,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(l10n.darkMode),
                  trailing: Switch(
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleTheme(value);
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
                // Sezione per la lingua
                ListTile(
                  leading: Icon(
                    Icons.language,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(l10n.language),
                  trailing: DropdownButton<String>(
                    value: preSettings.selectedLanguage,
                    icon: const Icon(Icons.arrow_drop_down),
                    underline: Container(),
                    onChanged: (String? value) {
                      if (value != null) {
                        preSettings.setLanguage(value);
                        Provider.of<LocaleProvider>(context, listen: false)
                            .setLocale(value);
                      }
                    },
                    items: preSettings.languageList
                        .map<DropdownMenuItem<String>>(
                            (String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),
                // Titolo Interessi
                Text(
                  l10n.interests,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                // Griglia degli interessi
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 4,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                  ),
                  itemCount: preSettings.standardInterests.length,
                  itemBuilder: (context, index) {
                    final interestKey = preSettings.standardInterests[index];
                    final translatedInterest = l10n.localize(interestKey);
                    final isSelected =
                        preSettings.selectedInterests[interestKey] ?? false;
                    return Card(
                      elevation: 0,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                      child: InkWell(
                        onTap: () {
                          preSettings.toggleInterest(interestKey, !isSelected);
                        },
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (bool? value) {
                                  if (value != null) {
                                    preSettings.toggleInterest(
                                        interestKey, value);
                                  }
                                },
                                activeColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                              Expanded(
                                child: Text(
                                  translatedInterest,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected
                                        ? (Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white
                                            : Colors.black)
                                        : (Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white70
                                            : Colors.black87),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () async {
                    await preSettings.savePreferences();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings saved'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    minimumSize: const Size(200, 48),
                    foregroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text(l10n.saveSettings),
                ),
                const SizedBox(height: 15),
                GestureDetector(
                  onTap: () {
                    _showConfirmDeleteAccountDialog(context);
                  },
                  child: Text(
                    'Delete account',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  void _editNickname() async {
    final preSettings =
        Provider.of<PreSettingsProvider>(context, listen: false);
    TextEditingController controller =
        TextEditingController(text: preSettings.nickname);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final l10n = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(l10n.editNickname),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: l10n.enterNickname,
            ),
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await preSettings.updateNickname(controller.text);
                  Navigator.of(context).pop();
                }
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation of deletion'),
          content: const Text(
              'Are you sure you want to delete your account? This action is irreversible.'),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAccount(context);
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        themeProvider.resetTheme();
        print("Account deleted with success");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Account deleted successfully')));
        Navigator.pushNamedAndRemoveUntil(
          context,
          "/",
          (Route<dynamic> route) => false,
        );
        await user.delete();
      }
    } catch (e) {
      print("Error during the elimination of account: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error deleting account. Please try again.')));
    }
  }
}