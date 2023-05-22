import 'package:biyi_app/includes.dart';
import 'package:biyi_app/networking/translate_client/pro_translation_engine.dart'
    show ProTranslationEngine;
export 'package:uni_translate/uni_translate.dart';

const kSupportedEngineTypes = [
  kEngineTypeBaidu,
  kEngineTypeCaiyun,
  kEngineTypeDeepL,
  kEngineTypeGoogle,
  kEngineTypeIciba,
  kEngineTypeTencent,
  kEngineTypeYoudao,
];

final Map<String, List<String>> kKnownSupportedEngineOptionKeys = {
  kEngineTypeBaidu: BaiduTranslationEngine.optionKeys,
  kEngineTypeCaiyun: CaiyunTranslationEngine.optionKeys,
  kEngineTypeDeepL: DeepLTranslationEngine.optionKeys,
  kEngineTypeGoogle: GoogleTranslationEngine.optionKeys,
  kEngineTypeIciba: IcibaTranslationEngine.optionKeys,
  kEngineTypeTencent: TencentTranslationEngine.optionKeys,
  kEngineTypeYoudao: YoudaoTranslationEngine.optionKeys,
};

TranslationEngine? createTranslationEngine(
  TranslationEngineConfig engineConfig,
) {
  if (localDb.proEngine(engineConfig.identifier).exists()) {
    return ProTranslationEngine(engineConfig);
  } else {
    switch (engineConfig.type) {
      case kEngineTypeBaidu:
        return BaiduTranslationEngine(
          identifier: engineConfig.identifier,
          option: engineConfig.option,
        );
      case kEngineTypeCaiyun:
        return CaiyunTranslationEngine(
          identifier: engineConfig.identifier,
          option: engineConfig.option,
        );
      case kEngineTypeDeepL:
        return DeepLTranslationEngine(
          identifier: engineConfig.identifier,
          option: engineConfig.option,
        );
      case kEngineTypeGoogle:
        return GoogleTranslationEngine(
          identifier: engineConfig.identifier,
          option: engineConfig.option,
        );
      case kEngineTypeIciba:
        return IcibaTranslationEngine(
          identifier: engineConfig.identifier,
          option: engineConfig.option,
        );
      case kEngineTypeTencent:
        return TencentTranslationEngine(
          identifier: engineConfig.identifier,
          option: engineConfig.option,
        );
      case kEngineTypeYoudao:
        return YoudaoTranslationEngine(
          identifier: engineConfig.identifier,
          option: engineConfig.option,
        );
      default:
        break;
    }
  }
  return null;
}

class AutoloadTranslateClientAdapter extends UniTranslateClientAdapter {
  final Map<String, TranslationEngine> _translationEngineMap = {};

  @override
  TranslationEngine get first {
    TranslationEngineConfig engineConfig = localDb.engines.list().first;
    return use(engineConfig.identifier);
  }

  @override
  TranslationEngine use(String identifier) {
    TranslationEngineConfig? engineConfig = localDb.engine(identifier).get();

    TranslationEngine? translationEngine;
    if (_translationEngineMap.containsKey(engineConfig?.identifier)) {
      translationEngine = _translationEngineMap[engineConfig?.identifier];
    }

    if (translationEngine == null) {
      translationEngine = createTranslationEngine(engineConfig!);

      if (translationEngine != null) {
        _translationEngineMap.update(
          engineConfig.identifier,
          (_) => translationEngine!,
          ifAbsent: () => translationEngine!,
        );
      }
    }

    return translationEngine!;
  }

  void renew(String identifier) {
    _translationEngineMap.remove(identifier);
  }
}

UniTranslateClient translateClient = UniTranslateClient(
  AutoloadTranslateClientAdapter(),
);
