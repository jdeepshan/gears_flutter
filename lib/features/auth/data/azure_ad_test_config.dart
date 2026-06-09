/// Temporary overrides for Azure AD login testing.
/// Set [enabled] to false once pathAD comes from the API.
abstract final class AzureAdTestConfig {
  static const enabled = false;
  static const pathAd = 'gutech';
}
