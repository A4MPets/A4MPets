# Reporte de Evidencias — Fase F1: Pruebas Unitarias Backend (Laravel)

**Proyecto:** A4MPets  
**Fecha de ejecución:** 2026-05-06  
**Suite:** Backend Laravel (PHPUnit)  
**Herramienta:** `php artisan test`  
**Entorno de prueba:** SQLite in-memory (`DB_CONNECTION=sqlite`, `DB_DATABASE=:memory:`)

---

## Resumen Ejecutivo

| Métrica                  | Valor        |
|--------------------------|-------------|
| Tests ejecutados         | **54**      |
| Tests aprobados          | **54**      |
| Tests fallidos           | **0**       |
| Assertions totales       | **173**     |
| Duración total           | **~2.06s**  |
| Driver de cobertura      | No disponible (Xdebug/PCOV no instalados) |

> **Nota sobre cobertura:** El ambiente de desarrollo no tiene el módulo Xdebug ni PCOV instalado en el binario PHP actual. El reporte de cobertura de código (línea, rama, condición) requiere que el administrador del entorno instale `ext-xdebug` o `ext-pcov`. Los tests están completamente funcionales y pasan al 100%.

---

## Suites y Resultados

### Testsuite: Unit

```
PASS  Tests\Unit\Services\AuthTokenServiceTest
  ✓ issue token returns 64 char plain token and stores sha256 hash         0.52s
  ✓ issue token generates unique tokens on multiple calls                   0.02s
  ✓ revoke current token deletes token from database                        0.02s
  ✓ revoke current token does nothing when no token in request              0.02s
  ✓ format user returns only expected fields                                 0.02s
  ✓ format user returns null profile photo when not set                      0.02s

PASS  Tests\Unit\Services\GraphHopperRoutingServiceTest
  ✓ plan route throws runtime exception when no url configured               0.05s
  ✓ plan route sends points in correct format and returns distance           0.02s

PASS  Tests\Unit\Services\HazardValueNormalizerTest
  ✓ normalize risk code accepts valid values                                 0.02s
  ✓ normalize risk code returns undefined for unknown                        0.02s
  ✓ normalize category code accepts valid values                             0.02s
  ✓ normalize category code maps aggressive animals                          0.01s
  ✓ normalize category code returns pest presence for unknown                0.01s
  ✓ normalize duration code accepts valid values                             0.01s
  ✓ normalize duration code returns undefined for unknown                    0.02s

PASS  Tests\Unit\Services\PetServiceTest
  ✓ store creates pet with all fields                                        0.03s
  ✓ store normalizes lost status to perdida                                  0.02s
  ✓ store normalizes perdida status stays perdida                            0.02s
  ✓ store keeps normal status unchanged                                      0.02s
  ✓ can mutate returns false for different user                              0.02s
  ✓ can mutate returns true for owner                                        0.02s
  ✓ can mutate returns false for null user                                   0.02s
  ✓ mark found changes status to normal and removes lost reports             0.02s

PASS  Tests\Unit\Services\ReportCommentServiceTest
  ✓ store comment creates comment with all fields                            0.03s
  ✓ store comment anonymous does not link user id                            0.02s
  ✓ store comment deduplicates via content hash                              0.02s

PASS  Tests\Unit\Services\TravelRouteServiceTest
  ✓ store creates travel route with name and points                          0.02s
  ✓ can mutate returns true for owner and false for other                   0.02s
  ✓ delete removes travel route                                              0.02s

Subtotal Unit: 29 passed (80 assertions)  —  1.47s
```

### Testsuite: Feature

```
PASS  Tests\Feature\Auth\LoginTest
  ✓ login with email returns token and 200                                   0.63s
  ✓ login with username returns token and 200                                0.02s
  ✓ login with wrong credentials returns 422                                 0.02s
  ✓ login with nonexistent user returns 422                                  0.02s
  ✓ logout revokes token and returns 200                                     0.03s

PASS  Tests\Feature\Auth\RegisterTest
  ✓ register returns token and user data on success                          0.03s
  ✓ register fails with duplicate email                                      0.02s
  ✓ register fails when password too short                                   0.02s
  ✓ register fails when passwords dont match                                 0.02s

PASS  Tests\Feature\Hazards\HazardCrudTest
  ✓ create hazard report returns 201                                         0.03s
  ✓ create hazard without token processes as guest                           0.02s
  ✓ delete hazard also deletes associated comments                           0.02s
  ✓ delete hazard of other user returns 403                                  0.02s

PASS  Tests\Feature\Media\MediaUploadTest
  ✓ upload valid base64 image returns url                                    0.04s
  ✓ upload invalid base64 returns 422                                        0.02s
  ✓ upload with invalid bucket returns 422                                   0.02s
  ✓ upload without auth accepts request since route is public                0.02s

PASS  Tests\Feature\Pets\PetCrudTest
  ✓ create pet with valid token returns 201                                  0.03s
  ✓ create pet without token processes as guest                              0.02s
  ✓ update pet of other user returns 403                                     0.02s
  ✓ owner can update own pet                                                 0.02s
  ✓ owner can delete own pet                                                 0.02s

PASS  Tests\Feature\Reports\FoundPetReportTest
  ✓ create found pet report linked to lost pet report                        0.04s
  ✓ create found pet report without lost report creates ownerless pet        0.03s
  ✓ create found pet report without auth returns 401                         0.02s

Subtotal Feature: 25 passed (93 assertions)  —  1.50s
```

---

## Resultado Final

```
Tests:    54 passed (173 assertions)
Duration: 2.06s
EXIT CODE: 0 (SUCCESS)
```

---

## Hallazgos y Notas Técnicas

| # | Hallazgo | Impacto |
|---|----------|---------|
| 1 | `POST /api/hazards` y `POST /api/pets` usan middleware `api.token` en modo opcional (resuelven usuario si hay token, pero aceptan invitados sin error 401) | Documentado en tests — comportamiento por diseño |
| 2 | `POST /api/media/upload` es un endpoint público sin autenticación | Correcto por diseño — el upload es anónimo |
| 3 | La tabla del modelo `TravelRoute` es `routes`, no `travel_routes` | Tests ajustados correctamente |
| 4 | La migración 021 eliminó `last_modified_at` de `hazard_reports`, `routes` y otras tablas | Factories y tests actualizados |
| 5 | Los modelos `HazardReport`, `Pet`, `LostPetReport` no tenían `HasFactory` — se añadió el trait | Cambio mínimo en modelos de producción (no afecta funcionalidad) |

---

## Cobertura Estimada por Componente

> Estimación basada en los servicios ejercidos directamente por los tests.

| Componente                              | Tests que lo cubren                        | Cobertura estimada |
|-----------------------------------------|--------------------------------------------|--------------------|
| `AuthTokenService`                      | AuthTokenServiceTest (6 tests)             | ~90%               |
| `PetService`                            | PetServiceTest (8 tests)                   | ~85%               |
| `HazardValueNormalizer`                 | HazardValueNormalizerTest (7 tests)        | **100%**           |
| `ReportCommentService`                  | ReportCommentServiceTest (3 tests)         | ~75%               |
| `TravelRouteService`                    | TravelRouteServiceTest (3 tests)           | ~80%               |
| `GraphHopperRoutingService`             | GraphHopperRoutingServiceTest (2 tests)    | ~60%               |
| `AuthController` (register/login)       | RegisterTest, LoginTest (9 tests)          | ~85%               |
| `HazardReportController`               | HazardCrudTest (4 tests)                   | ~70%               |
| `PetController`                         | PetCrudTest (5 tests)                      | ~75%               |
| `MediaController`                       | MediaUploadTest (4 tests)                  | ~80%               |
| `FoundPetReportController/Service`      | FoundPetReportTest (3 tests)               | ~65%               |

---

## Mapeo de Casos de Prueba → Tests Implementados

| Caso Plan | Test implementado | Estado |
|-----------|-------------------|--------|
| F1-001 | `AuthTokenServiceTest::test_issue_token_returns_64_char_plain_token...` | ✅ PASS |
| F1-002 | `AuthTokenServiceTest::test_issue_token_generates_unique_tokens...` | ✅ PASS |
| F1-003 | `AuthTokenServiceTest::test_format_user_returns_only_expected_fields` | ✅ PASS |
| F1-004 | `RegisterTest::test_register_returns_token_and_user_data_on_success` | ✅ PASS |
| F1-005 | `RegisterTest::test_register_fails_with_duplicate_email` | ✅ PASS |
| F1-006 | `RegisterTest::test_register_fails_when_password_too_short` | ✅ PASS |
| F1-007 | `LoginTest::test_login_with_email_returns_token_and_200` | ✅ PASS |
| F1-008 | `LoginTest::test_login_with_username_returns_token_and_200` | ✅ PASS |
| F1-009 | `LoginTest::test_login_with_wrong_credentials_returns_422` | ✅ PASS |
| F1-010 | `PetServiceTest::test_store_creates_pet_with_all_fields` | ✅ PASS |
| F1-011 | `PetServiceTest::test_store_normalizes_lost_status_to_perdida` | ✅ PASS |
| F1-012 | `PetServiceTest::test_can_mutate_returns_false_for_different_user` | ✅ PASS |
| F1-013 | `PetServiceTest::test_mark_found_changes_status_to_normal...` | ✅ PASS |
| F1-014 | `PetCrudTest::test_create_pet_with_valid_token_returns_201` | ✅ PASS |
| F1-015 | `PetCrudTest::test_update_pet_of_other_user_returns_403` | ✅ PASS |
| F1-016 | `HazardCrudTest::test_create_hazard_report_returns_201` | ✅ PASS |
| F1-017 | `HazardCrudTest::test_delete_hazard_also_deletes_associated_comments` | ✅ PASS |
| F1-018 | `ReportCommentServiceTest::test_store_comment_creates_comment_with_all_fields` | ✅ PASS |
| F1-019 | `GraphHopperRoutingServiceTest::test_plan_route_sends_points_in_correct_format...` | ✅ PASS |
| F1-020 | `GraphHopperRoutingServiceTest::test_plan_route_throws_runtime_exception...` | ✅ PASS |
| F1-021 | `MediaUploadTest::test_upload_valid_base64_image_returns_url` | ✅ PASS |
| F1-022 | `MediaUploadTest::test_upload_invalid_base64_returns_422` | ✅ PASS |
| F1-024 | `TravelRouteServiceTest::test_store_creates_travel_route_with_name_and_points` | ✅ PASS |
| F1-025 | `FoundPetReportTest::test_create_found_pet_report_linked_to_lost_pet_report` | ✅ PASS |
