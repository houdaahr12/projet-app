
import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../services/auth_service.dart';
import '../services/doctor_service.dart';
import '../widgets/dashboard_banner.dart';
import '../widgets/doctor_card.dart';
import '../widgets/doctor_filters.dart';
import '../widgets/doctor_form_dialog.dart';
import '../widgets/stat_card.dart';
import '../widgets/ui.dart';
import 'login_admin.dart';

class GestionMedecins extends StatefulWidget {
  const GestionMedecins({super.key});

  @override
  State<GestionMedecins> createState() => _GestionMedecinsState();
}

class _GestionMedecinsState extends State<GestionMedecins> {
  List<Doctor> doctors = [];
  DoctorStats? stats;

  bool loading = true;
  String search = '';
  FiltreStatut filtre = FiltreStatut.tous;

  Timer? debounce;
  final searchController = TextEditingController();
  final listeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  // DONNEES 

  List<Doctor> get visibles {
    switch (filtre) {
      case FiltreStatut.actifs:
        return doctors.where((d) => d.actif).toList();

      case FiltreStatut.inactifs:
        return doctors.where((d) => !d.actif).toList();

      case FiltreStatut.tous:
        return doctors;
    }
  }

  int get nbTous => stats?.total ?? doctors.length;

  int get nbActifs =>
      stats?.actifs ?? doctors.where((d) => d.actif).length;

  int get nbInactifs =>
      stats?.inactifs ?? doctors.where((d) => !d.actif).length;

  Future<void> loadData({bool silent = false}) async {
    if (!mounted) return;

    if (!silent) {
      setState(() => loading = true);
    }

    try {
      final results = await Future.wait([
        DoctorService.getDoctors(q: search),
        DoctorService.getStats(),
      ]);

      if (!mounted) return;

      setState(() {
        doctors = results[0] as List<Doctor>;
        stats = results[1] as DoctorStats;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      final message = e.toString();

      if (message.contains('Session expirée') ||
          message.contains('401')) {
        await logout();
        return;
      }

      showMessage(message.replaceFirst('Exception: ', ''));
    }
  }

  //  RECHERCHE 

  void onSearchChanged(String value) {
    setState(() {});

    debounce?.cancel();

    debounce = Timer(const Duration(milliseconds: 450), () {
      search = value.trim();
      loadData(silent: true);
    });
  }

  void clearSearch() {
    debounce?.cancel();
    searchController.clear();
    search = '';

    setState(() {});

    loadData(silent: true);
  }

  void reinitialiserFiltres() {
    debounce?.cancel();

    searchController.clear();
    search = '';

    setState(() {
      filtre = FiltreStatut.tous;
    });

    loadData(silent: true);
  }

  void afficherTous() {
    setState(() {
      filtre = FiltreStatut.tous;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = listeKey.currentContext;

      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void choisirFiltre(FiltreStatut value) {
    setState(() => filtre = value);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = listeKey.currentContext;

      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  //  MESSAGES 

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  //  DECONNEXION

  Future<void> logout() async {
    await AuthService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginAdmin(),
      ),
      (route) => false,
    );
  }

  // FORMULAIRE 

  Future<void> openDoctorForm({Doctor? doctor}) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Formulaire médecin',
      barrierColor: Colors.black.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: DoctorFormDialog(doctor: doctor),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.88,
              end: 1,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );

    if (result == true) {
      await loadData(silent: true);

      if (!mounted) return;

      showMessage(
        doctor == null
            ? 'Médecin ajouté avec succès'
            : 'Médecin modifié avec succès',
      );
    }
  }

  //  DESACTIVATION 

  Future<void> deactivateDoctor(Doctor doctor) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.red,
          size: 42,
        ),
        title: const Text(
          'Désactiver le médecin ?',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Voulez-vous vraiment désactiver le compte de ${doctor.nom} ?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
            ),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await DoctorService.deleteDoctor(doctor.id);
      await loadData(silent: true);

      if (!mounted) return;

      showMessage('Compte médecin désactivé');
    } catch (e) {
      if (!mounted) return;

      showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  //  REACTIVATION 

  Future<void> reactivateDoctor(Doctor doctor) async {
    try {
      await DoctorService.updateDoctor(
        id: doctor.id,
        nom: doctor.nom,
        identifiant: doctor.identifiant,
        email: doctor.email ?? '',
        service: doctor.service ?? '',
        motDePasse: '',
        actif: true,
        sexe: doctor.sexe,
      );

      await loadData(silent: true);

      if (!mounted) return;

      showMessage('Compte médecin activé');
    } catch (e) {
      if (!mounted) return;

      showMessage(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  //  ETAT VIDE 

  Widget etatVide() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 45,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1EAF4)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: AppColors.lightBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 38,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Aucun médecin trouvé',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Essayez de modifier votre recherche ou vos filtres.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: reinitialiserFiltres,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  //  GRILLE 

  Widget grille() {
    final items = visibles;

    if (items.isEmpty) return etatVide();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        final colonnes = w >= 1050
            ? 4
            : w >= 760
                ? 3
                : w >= 480
                    ? 2
                    : 1;

        const ecart = 14.0;

        final largeur =
            (w - (colonnes - 1) * ecart) / colonnes;

        return Wrap(
          spacing: ecart,
          runSpacing: ecart,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final doctor = entry.value;

            return SizedBox(
              width: largeur,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(doctor.id),
                tween: Tween(begin: 0, end: 1),
                duration: Duration(
                  milliseconds: 350 + (index * 70).clamp(0, 350).toInt(),
                ),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: DoctorCard(
                  doctor: doctor,
                  onEdit: () => openDoctorForm(doctor: doctor),
                  onDeactivate: () => deactivateDoctor(doctor),
                  onReactivate: () => reactivateDoctor(doctor),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  //  CONTENU 

  Widget content() {
    return RefreshIndicator(
      onRefresh: () => loadData(silent: true),
      color: AppColors.blue,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 640;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1250),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardBanner(
                      compact: compact,
                      onShowList: afficherTous,
                    ),

                    const SizedBox(height: 16),

                    StatsRow(
                      total: nbTous,
                      actifs: nbActifs,
                      inactifs: nbInactifs,
                      compact: compact,
                      onSelect: choisirFiltre,
                    ),

                    const SizedBox(height: 22),

                    if (compact) ...[
                      StatusFilterBar(
                        filtre: filtre,
                        onChanged: choisirFiltre,
                      ),
                      const SizedBox(height: 12),
                      DoctorSearchBar(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        onClear: clearSearch,
                      ),
                    ] else
                      Row(
                        children: [
                          Expanded(
                            flex: 5,
                            child: StatusFilterBar(
                              filtre: filtre,
                              onChanged: choisirFiltre,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            flex: 7,
                            child: DoctorSearchBar(
                              controller: searchController,
                              onChanged: onSearchChanged,
                              onClear: clearSearch,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 22),

                    Row(
                      key: listeKey,
                      children: [
                        const Icon(
                          Icons.groups_rounded,
                          color: AppColors.blue,
                          size: 22,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          '${visibles.length} médecin${visibles.length > 1 ? 's' : ''} affiché${visibles.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Actualiser',
                          onPressed: () => loadData(silent: true),
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: AppColors.blue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: KeyedSubtree(
                        key: ValueKey(
                          '$filtre-${searchController.text}-${visibles.map((d) => d.id).join(",")}',
                        ),
                        child: grille(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // APPBAR 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 68,

        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.monitor_heart_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SepsisCare',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Administration',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: () => loadData(),
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 14),
            width: 1,
            color: const Color(0xFFE6EDF5),
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 17,
            backgroundColor: AppColors.lightBlue,
            child: Icon(
              Icons.person_rounded,
              color: AppColors.blue,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Admin',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Menu',
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.navy,
            ),
            onSelected: (value) {
              if (value == 'logout') logout();
              if (value == 'refresh') loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, size: 19),
                    SizedBox(width: 10),
                    Text('Actualiser'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 19,
                      color: AppColors.red,
                    ),
                    SizedBox(width: 10),
                    Text('Déconnexion'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openDoctorForm(),
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        elevation: 5,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter un médecin'),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.blue,
              ),
            )
          : content(),
    );
  }
}