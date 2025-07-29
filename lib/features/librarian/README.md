# Librarian Dashboard

The Librarian Dashboard is a comprehensive task management interface designed specifically for librarians to manage, track, and archive tasks within the application.

## Features

- **Task Overview**: View all tasks with filtering by status (All, Completed, Pending)
- **Advanced Filtering**: Filter tasks by status, category, tags, date range, and assigned users
- **Search**: Full-text search across task titles, descriptions, categories, and tags
- **Task Details**: View detailed information about each task, including metadata and assigned users
- **Archive Management**: Archive and unarchive tasks with optional archive reasons and locations
- **Export**: Export tasks in PDF or CSV format for reporting and record-keeping
- **Responsive Design**: Works on mobile, tablet, and desktop devices

## Components

### Screens

- `LibrarianDashboardScreen`: Main dashboard with task list and filtering options
- `LibrarianTaskDetailScreen`: Detailed view of a single task

### Widgets

- `TaskListView`: Displays a list of tasks with filtering and sorting
- `LibrarianTaskCard`: Card widget for displaying task previews
- `TaskActions`: Action buttons for task operations (archive, export, etc.)
- `ArchiveStatsCard`: Displays statistics about archived tasks
- `TaskFiltersSheet`: Bottom sheet for applying advanced filters

### Services

- `ArchiveService`: Handles task archiving and unarchiving
- `ExportService`: Handles exporting tasks to different formats (PDF, CSV)

## Usage

### Navigating to the Librarian Dashboard

Librarian users will be automatically redirected to the dashboard after login. You can also navigate to it using:

```dart
Get.toNamed(Routes.librarianDashboard);
```

### Filtering Tasks

1. Tap the filter icon in the app bar
2. Select your filter criteria:
   - Status (Pending, In Progress, Completed, Archived)
   - Date range
   - Categories
   - Tags
   - Assigned users
3. Tap "Apply Filters" to apply the filters

### Archiving Tasks

1. Locate the task you want to archive
2. Tap the archive icon (box with a down arrow) on the task card
3. Enter a reason for archiving (required)
4. Optionally, specify a location (physical or digital)
5. Tap "Archive" to confirm

### Exporting Tasks

1. To export a single task:
   - Tap the three dots menu on the task card
   - Select "Export as PDF" or "Export as CSV"

2. To export multiple tasks:
   - Apply any desired filters
   - Tap the share icon in the app bar
   - Select "Export as PDF" or "Export as CSV"

## Data Model

The librarian dashboard extends the base `Task` model with the following fields:

- `archivedAt`: When the task was archived
- `archivedBy`: Who archived the task
- `archiveReason`: Reason for archiving
- `archiveLocation`: Physical or digital location of the archived task

## Dependencies

- `get`: For state management and dependency injection
- `intl`: For date formatting
- `pdf`: For PDF generation
- `share_plus`: For sharing exported files

## Testing

To test the librarian dashboard:

1. Log in as a user with the 'librarian' role
2. Verify that you can view all tasks
3. Test filtering by different criteria
4. Test archiving and unarchiving tasks
5. Test exporting tasks in both PDF and CSV formats

## Known Issues

- None at this time

## Future Enhancements

- Bulk archive/export operations
- Custom report generation
- Integration with external document management systems
