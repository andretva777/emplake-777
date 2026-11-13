import 'package:flutter/material.dart';

import '../../settings/app_theme.dart';

/// Placa de carro estilizada. As cores são fixas (é um objeto físico), então
/// ela tem a mesma aparência nos temas claro e escuro.
class LicensePlate extends StatelessWidget {
  const LicensePlate({
    super.key,
    required this.text,
    required this.country,
    this.height = 64,
  });

  final String text;
  final String country;
  final double height;

  static const _blue = Color(0xFF0B3D91);
  static const _body = Color(0xFFF7F7F2);
  static const _ink = Color(0xFF16181D);

  @override
  Widget build(BuildContext context) {
    final band = height * 0.26;
    return Semantics(
      label: text.split('').join(' '),
      excludeSemantics: true,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: _body,
          borderRadius: BorderRadius.circular(height * 0.14),
          border: Border.all(color: _ink, width: height * 0.045),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: band,
                color: _blue,
                alignment: Alignment.center,
                child: Text(
                  country,
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: band * 0.62,
                    fontWeight: FontWeight.w700,
                    letterSpacing: band * 0.25,
                    height: 1,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: height * 0.32),
                  child: Center(
                    child: Text(
                      text,
                      textScaler: TextScaler.noScaling,
                      style: mathStyle(
                        context,
                        size: height * 0.5,
                        color: _ink,
                      ).copyWith(letterSpacing: height * 0.12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
