import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:changaya/core/widgets/error_snackbar.dart';
import 'package:changaya/core/widgets/loading_button.dart';
import 'package:changaya/features/auth/presentation/providers/auth_providers.dart';
import 'package:changaya/features/profile/domain/user_profile.dart';
import 'package:changaya/features/profile/presentation/providers/save_profile_notifier.dart';

// The generated provider name for SaveProfileNotifier is saveProfileProvider
// (see save_profile_notifier.g.dart).

/// Keys para los campos del form — usadas en widget tests.
const completeProfilePhoneFieldKey = Key('complete_profile_phone_field');

/// Pantalla de completar perfil en onboarding (P-08).
///
/// Recolecta teléfono y localidad (campos obligatorios).
/// La foto de perfil es opcional.
/// Guarda usando [SaveProfileNotifier].
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() =>
      _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String? _selectedLocalidad;
  bool _localidadTouched = false;

  static const List<String> _localidades = [
    'Formosa Capital',
    'Clorinda',
    'Las Lomitas',
    'Ingeniero Juárez',
    'Pirané',
    'General Lucio Victorio Mansilla',
    'El Colorado',
    'Comandante Fontana',
    'Laguna Blanca',
    'Ibarreta',
    'Pozo del Tigre',
    'Misión Laishí',
    'General Belgrano',
    'Villa Dos Trece',
    'Subteniente Perín',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String _normalizePhone(String phone) {
    return UserProfile.normalizePhone(phone);
  }

  Future<void> _saveProfile() async {
    setState(() => _localidadTouched = true);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedLocalidad == null) return;

    final authAsync = ref.read(authStateChangesProvider);
    final user = authAsync.value;
    if (user == null) return;

    final normalizedPhone = _normalizePhone(_phoneController.text);

    final profile = UserProfile(
      uid: user.uid,
      displayName: user.displayName ?? user.email,
      phone: normalizedPhone,
      localidad: _selectedLocalidad,
      onboardingComplete: true,
    );

    final notifier = ref.read(saveProfileProvider.notifier);
    await notifier.saveProfile(profile);

    if (!mounted) return;
    final state = ref.read(saveProfileProvider);
    if (state is AsyncError) {
      showErrorSnackbar(
        context,
        'No se pudo guardar el perfil. Intentá de nuevo.',
      );
      return;
    }
    // Navegación imperativa tras save exitoso. Patrón híbrido:
    //   - Declarativo (GoRouter redirect) por default para cambios de estado.
    //   - Imperativo acá porque es una acción explícita del usuario y el
    //     listener del userProfileProvider puede ser lento/flaky contra el
    //     emulador (documentado en docs/troubleshooting.md).
    // Ya sabemos que onboardingComplete=true porque lo acabamos de guardar.
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saveState = ref.watch(saveProfileProvider);
    final isLoading = saveState is AsyncLoading;
    // Watch authStateChangesProvider in build to ensure the stream is subscribed
    // before _saveProfile() calls ref.read(authStateChangesProvider).
    ref.watch(authStateChangesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Completá tu perfil'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Foto de perfil',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Center(
                  child: Stack(
                    children: [
                      const CircleAvatar(
                        radius: 48,
                        child: Icon(Icons.person, size: 48),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: IconButton.filled(
                          icon: const Icon(Icons.camera_alt, size: 20),
                          // TODO(tech-debt): implementar selección y upload de foto.
                          // Trabajo pendiente:
                          //   1. image_picker → galería/cámara
                          //   2. flutter_image_compress → 1024px, calidad 80%
                          //   3. profileRepository.uploadProfilePhoto(uid, xfile)
                          //      (ya existe en FirestoreProfileRepository)
                          //   4. Actualizar UserProfile con la URL devuelta
                          //   5. Mostrar la foto en el CircleAvatar
                          //   6. Tests (widget + integration)
                          // Spec I-02: foto marcada como opcional — diferida a ticket
                          // futuro. Ver memoria engram: techdebt/profile-photo-upload.
                          onPressed: null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  key: completeProfilePhoneFieldKey,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    hintText: '03624 123456',
                    prefixText: '+54 ',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Ingresá tu teléfono';
                    }
                    final normalized = _normalizePhone(value);
                    if (normalized.length < 10 || normalized.length > 11) {
                      return 'El teléfono debe tener 10 u 11 dígitos';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _selectedLocalidad,
                  decoration: const InputDecoration(
                    labelText: 'Localidad',
                  ),
                  hint: const Text('Seleccioná tu localidad'),
                  items: _localidades
                      .map(
                        (loc) => DropdownMenuItem(
                          value: loc,
                          child: Text(loc),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedLocalidad = val;
                      _localidadTouched = true;
                    });
                  },
                  validator: (_) {
                    if (_localidadTouched && _selectedLocalidad == null) {
                      return 'Seleccioná tu localidad';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                LoadingButton(
                  onPressed: isLoading ? null : _saveProfile,
                  label: 'Guardar perfil',
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
