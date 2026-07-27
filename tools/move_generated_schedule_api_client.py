#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OLD_CLIENT = (
    ROOT
    / "lib/features/doubles_scheduler/infrastructure/generated_schedule_api_client.dart"
)
NEW_CLIENT = ROOT / "lib/shared/infrastructure/generated_schedule_api_client.dart"

SHARED_IMPORT = (
    b"import 'package:srp_lanske/shared/infrastructure/"
    b"generated_schedule_api_client.dart';"
)

REPLACEMENTS = {
    ROOT / "lib/features/doubles_scheduler/application/generated_schedule_service.dart": (
        b"import '../infrastructure/generated_schedule_api_client.dart';",
        SHARED_IMPORT,
    ),
    ROOT / "lib/features/doubles_scheduler/presentation/schedule_page.dart": (
        b"import '../infrastructure/generated_schedule_api_client.dart';",
        SHARED_IMPORT,
    ),
    ROOT / "lib/features/doubles_scheduler/presentation/restored_schedule_page.dart": (
        b"import '../infrastructure/generated_schedule_api_client.dart';",
        SHARED_IMPORT,
    ),
    ROOT / "lib/features/team_scheduler/application/team_generated_schedule_service.dart": (
        b"import 'package:srp_lanske/features/doubles_scheduler/"
        b"infrastructure/generated_schedule_api_client.dart';",
        SHARED_IMPORT,
    ),
    ROOT / "lib/features/team_scheduler/presentation/team_schedule_page.dart": (
        b"import 'package:srp_lanske/features/doubles_scheduler/"
        b"infrastructure/generated_schedule_api_client.dart';",
        SHARED_IMPORT,
    ),
}


def move_client() -> None:
    if OLD_CLIENT.exists():
        content = OLD_CLIENT.read_bytes()
        NEW_CLIENT.parent.mkdir(parents=True, exist_ok=True)

        if NEW_CLIENT.exists() and NEW_CLIENT.read_bytes() != content:
            raise RuntimeError(f"destination already exists with different content: {NEW_CLIENT}")

        NEW_CLIENT.write_bytes(content)
        OLD_CLIENT.unlink()
        print(f"moved: {OLD_CLIENT.relative_to(ROOT)} -> {NEW_CLIENT.relative_to(ROOT)}")
        return

    if not NEW_CLIENT.exists():
        raise RuntimeError("generated schedule API client was not found")

    print(f"already moved: {NEW_CLIENT.relative_to(ROOT)}")


def update_imports() -> None:
    for path, (old, new) in REPLACEMENTS.items():
        content = path.read_bytes()
        count = content.count(old)

        if count == 0 and new in content:
            print(f"already updated: {path.relative_to(ROOT)}")
            continue

        if count != 1:
            raise RuntimeError(
                f"{path.relative_to(ROOT)}: expected exactly one import replacement, "
                f"found {count}"
            )

        path.write_bytes(content.replace(old, new, 1))
        print(f"updated: {path.relative_to(ROOT)}")


def validate() -> None:
    forbidden = (
        b"features/doubles_scheduler/infrastructure/"
        b"generated_schedule_api_client.dart",
        b"../infrastructure/generated_schedule_api_client.dart",
    )

    for path in (ROOT / "lib").rglob("*.dart"):
        content = path.read_bytes()
        for value in forbidden:
            if value in content:
                raise RuntimeError(
                    f"old generated schedule API client import remains: "
                    f"{path.relative_to(ROOT)}"
                )

    if OLD_CLIENT.exists():
        raise RuntimeError(f"old client still exists: {OLD_CLIENT.relative_to(ROOT)}")
    if not NEW_CLIENT.exists():
        raise RuntimeError(f"new client is missing: {NEW_CLIENT.relative_to(ROOT)}")

    print("validation passed")


move_client()
update_imports()
validate()
