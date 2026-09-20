## Purpose

El ridge sigue dando trabajo tras el Alpha: Sella ofrece cacerías repetibles que convierten el viaje de vuelta en rutina rentable en vez de despedida.

## ADDED Requirements

### Requirement: Contratos repetibles

Las quests con `repeatable: true` SHALL no entrar en `done` al completarse y SHALL volver a estar disponibles (aceptar → cazar → cobrar → repetir); SHALL requerir la 206 y no desbloquear nada.

#### Scenario: Repetir contrato

- **WHEN** se completa la 207 y se vuelve a hablar con Sella
- **THEN** la 207 está disponible de nuevo y al completarla otra vez otorga su recompensa
