# WanderHome Invoice Generator - Architecture Plan

## Overview
A modern, professional invoice generation app with a clean Material Design 3 interface. Users can create, customize, and export invoices for their business needs.

## Core Features
1. **Invoice Creation** - Form-based invoice builder with client details, services, amounts
2. **Invoice Preview** - Real-time preview of formatted invoice
3. **Template Management** - Save and reuse invoice templates
4. **Export Options** - Generate PDF or shareable text format
5. **Client Management** - Store and manage client information
6. **Local Storage** - Save invoices and client data locally

## Technical Architecture

### Core Components
1. **Models** (`lib/models/`)
   - `invoice_model.dart` - Invoice data structure
   - `client_model.dart` - Client information structure
   - `invoice_item_model.dart` - Line item structure

2. **Services** (`lib/services/`)
   - `local_storage_service.dart` - SharedPreferences for data persistence
   - `invoice_service.dart` - Invoice CRUD operations
   - `export_service.dart` - PDF/text export functionality

3. **Screens** (`lib/screens/`)
   - `home_screen.dart` - Dashboard with recent invoices
   - `create_invoice_screen.dart` - Invoice creation form
   - `invoice_preview_screen.dart` - Preview and export
   - `client_management_screen.dart` - Client CRUD operations
   - `settings_screen.dart` - App settings and preferences

4. **Widgets** (`lib/widgets/`)
   - `invoice_card.dart` - Reusable invoice display card
   - `client_card.dart` - Client information card
   - `invoice_form_fields.dart` - Reusable form components
   - `custom_app_bar.dart` - App-wide app bar component

### Data Flow
1. User creates invoice through form interface
2. Invoice data is validated and stored locally
3. Real-time preview updates as user types
4. Export functionality generates formatted output
5. Invoices are saved to local storage for future reference

### Design Patterns
- **Provider Pattern** for state management
- **Repository Pattern** for data access
- **Factory Pattern** for invoice template creation
- **Singleton Pattern** for services

### Dependencies Required
- `shared_preferences` - Local data storage
- `pdf` - PDF generation
- `provider` - State management
- `intl` - Date formatting and localization

## Implementation Priority
1. Create data models and services
2. Implement basic invoice creation form
3. Add preview functionality
4. Implement local storage
5. Add client management
6. Implement export features
7. Add polish and animations
8. Testing and debugging

## File Structure
```
lib/
├── main.dart
├── theme.dart
├── models/
│   ├── invoice_model.dart
│   ├── client_model.dart
│   └── invoice_item_model.dart
├── services/
│   ├── local_storage_service.dart
│   ├── invoice_service.dart
│   └── export_service.dart
├── screens/
│   ├── home_screen.dart
│   ├── create_invoice_screen.dart
│   ├── invoice_preview_screen.dart
│   ├── client_management_screen.dart
│   └── settings_screen.dart
└── widgets/
    ├── invoice_card.dart
    ├── client_card.dart
    ├── invoice_form_fields.dart
    └── custom_app_bar.dart
```

## Key Design Principles
- Clean, professional interface suitable for business use
- Intuitive form-based workflow
- Real-time preview capabilities
- Responsive design for various screen sizes
- Proper error handling and validation
- Modern Material Design 3 aesthetics