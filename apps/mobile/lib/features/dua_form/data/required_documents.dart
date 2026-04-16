/// Required-documents checklist per regimen.
///
/// Codes match UNCL1001 / ATENA `codigoDocumento` field. MVP covers
/// the regime codes the Vertivo pilot actually uses. The real list
/// lives in the RIMM catalog — we stub here until the lookup ships.
library;

import '../dua_form_state.dart';

/// Returns the baseline required-documents for a transport + regimen
/// combo. Today we key only on transportMode because the regimen
/// selector lands with a later ticket; once regimen is captured, this
/// function will take (regimen, transport) as input.
List<DuaDraftDocument> defaultRequiredDocuments({
  String? transportModeCode,
}) {
  final base = <DuaDraftDocument>[
    const DuaDraftDocument(
      code: '380',
      displayName: 'Factura comercial',
      required: true,
    ),
    const DuaDraftDocument(
      code: '271',
      displayName: 'Lista de empaque',
      required: true,
    ),
  ];

  // Sea / air transport needs a transport document (BL or AWB).
  if (transportModeCode == '1' || transportModeCode == '8') {
    base.add(const DuaDraftDocument(
      code: '705',
      displayName: 'Bill of Lading',
      required: true,
    ));
  } else if (transportModeCode == '4') {
    base.add(const DuaDraftDocument(
      code: '740',
      displayName: 'Air Waybill (AWB)',
      required: true,
    ));
  } else if (transportModeCode == '3') {
    base.add(const DuaDraftDocument(
      code: '730',
      displayName: 'Carta de porte terrestre',
      required: true,
    ));
  }

  // Optional — agent can opt in.
  base.addAll(const [
    DuaDraftDocument(
      code: '861',
      displayName: 'Certificado de origen (TLC)',
      required: false,
    ),
    DuaDraftDocument(
      code: '933',
      displayName: 'Permiso / nota tecnica VUCE',
      required: false,
    ),
  ]);

  return base;
}
