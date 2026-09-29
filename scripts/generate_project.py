#!/usr/bin/env python3
from __future__ import annotations

import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
APP_DIR = ROOT / "TheGameIsLying"
TEST_DIR = ROOT / "TheGameIsLyingTests"
UITEST_DIR = ROOT / "TheGameIsLyingUITests"
PROJ = ROOT / "TheGameIsLying.xcodeproj"


def uid(name: str) -> str:
    return hashlib.md5(name.encode()).hexdigest()[:24].upper()


def collect(folder: Path, suffixes: tuple[str, ...]) -> list[Path]:
    return sorted(
        [p for p in folder.rglob("*") if p.is_file() and p.suffix in suffixes],
        key=lambda p: str(p).lower(),
    )


def posix(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def main() -> None:
    swift_app = collect(APP_DIR, (".swift",))
    swift_test = collect(TEST_DIR, (".swift",))
    swift_uitest = collect(UITEST_DIR, (".swift",)) if UITEST_DIR.exists() else []
    resources = collect(APP_DIR, (".wav", ".xcprivacy"))
    assets = [APP_DIR / "Assets.xcassets"]

    ids = {k: uid(k) for k in [
        "project", "app_target", "test_target", "uitest_target", "app_product", "test_product", "uitest_product",
        "root", "products", "src_app", "fw_app", "res_app", "src_test", "fw_test",
        "res_test", "src_uitest", "fw_uitest", "res_uitest", "cfg_proj", "cfg_app", "cfg_test", "cfg_uitest",
        "debug_proj", "release_proj",
        "debug_app", "release_app", "debug_test", "release_test", "debug_uitest", "release_uitest",
        "proxy", "dep", "proxy_ui", "dep_ui",
    ]}

    file_refs: dict[Path, str] = {}
    build_files: dict[Path, str] = {}
    for path in swift_app + swift_test + swift_uitest + resources + assets:
        file_refs[path] = uid(f"ref:{posix(path)}")
        build_files[path] = uid(f"build:{posix(path)}")

    extra_groups: list[str] = []
    extra_group_ids: dict[Path, str] = {}

    def ensure_group(path: Path) -> str:
        extra_group_ids.setdefault(path, uid(f"group:{posix(path)}"))
        return extra_group_ids[path]

    def emit_group(path: Path) -> None:
        gid = ensure_group(path)
        kids = []
        for child in sorted(path.iterdir(), key=lambda p: p.name.lower()):
            if child.name == ".DS_Store":
                continue
            if child.is_dir() and child.suffix != ".xcassets":
                emit_group(child)
                kids.append(f"\t\t\t\t{ensure_group(child)} /* {child.name} */,\n")
            elif child in file_refs:
                kids.append(f"\t\t\t\t{file_refs[child]} /* {child.name} */,\n")
        extra_groups.append(
            f"\t\t{gid} /* {path.name} */ = {{\n"
            f"\t\t\tisa = PBXGroup;\n"
            f"\t\t\tchildren = (\n{''.join(kids)}\t\t\t);\n"
            f"\t\t\tpath = {path.name};\n"
            f"\t\t\tsourceTree = \"<group>\";\n"
            f"\t\t}};\n"
        )

    emit_group(APP_DIR)
    emit_group(TEST_DIR)
    if UITEST_DIR.exists():
        emit_group(UITEST_DIR)

    fileref_section = [
        f"\t\t{ids['app_product']} /* TheGameIsLying.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = TheGameIsLying.app; sourceTree = BUILT_PRODUCTS_DIR; }};\n",
        f"\t\t{ids['test_product']} /* TheGameIsLyingTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = TheGameIsLyingTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};\n",
        f"\t\t{ids['uitest_product']} /* TheGameIsLyingUITests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = TheGameIsLyingUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};\n",
    ]
    for path, ref in file_refs.items():
        name = path.name
        if path.suffix == ".swift":
            ftype = "sourcecode.swift"
        elif path.suffix == ".wav":
            ftype = "audio.wav"
        elif path.suffix == ".xcprivacy":
            ftype = "text.xml"
        else:
            ftype = "folder.assetcatalog"
        fileref_section.append(
            f"\t\t{ref} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = {ftype}; path = {name}; sourceTree = \"<group>\"; }};\n"
        )

    buildfile_section = []
    for path, bid in build_files.items():
        name = path.name
        kind = "Sources" if path.suffix == ".swift" else "Resources"
        buildfile_section.append(
            f"\t\t{bid} /* {name} in {kind} */ = {{isa = PBXBuildFile; fileRef = {file_refs[path]} /* {name} */; }};\n"
        )

    app_sources = "".join(f"\t\t\t\t{build_files[p]} /* {p.name} in Sources */,\n" for p in swift_app)
    test_sources = "".join(f"\t\t\t\t{build_files[p]} /* {p.name} in Sources */,\n" for p in swift_test)
    uitest_sources = "".join(f"\t\t\t\t{build_files[p]} /* {p.name} in Sources */,\n" for p in swift_uitest)
    app_resources = "".join(f"\t\t\t\t{build_files[p]} /* {p.name} in Resources */,\n" for p in resources + assets)
    uitest_group_child = (
        f"\t\t\t\t{extra_group_ids[UITEST_DIR]} /* TheGameIsLyingUITests */,\n" if UITEST_DIR.exists() else ""
    )

    pbx = f"""// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
{''.join(buildfile_section)}/* End PBXBuildFile section */

/* Begin PBXContainerItemProxy section */
		{ids['proxy']} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {ids['project']} /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = {ids['app_target']};
			remoteInfo = TheGameIsLying;
		}};
		{ids['proxy_ui']} /* PBXContainerItemProxy */ = {{
			isa = PBXContainerItemProxy;
			containerPortal = {ids['project']} /* Project object */;
			proxyType = 1;
			remoteGlobalIDString = {ids['app_target']};
			remoteInfo = TheGameIsLying;
		}};
/* End PBXContainerItemProxy section */

/* Begin PBXFileReference section */
{''.join(fileref_section)}/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{ids['fw_app']} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{ids['fw_test']} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
 mar			runOnlyForDeploymentPostprocessing = 0;
		}};
		{ids['fw_uitest']} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{ids['root']} = {{
			isa = PBXGroup;
			children = (
				{extra_group_ids[APP_DIR]} /* TheGameIsLying */,
				{extra_group_ids[TEST_DIR]} /* TheGameIsLyingTests */,
{uitest_group_child}				{ids['products']} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{ids['products']} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{ids['app_product']} /* TheGameIsLying.app */,
				{ids['test_product']} /* TheGameIsLyingTests.xctest */,
				{ids['uitest_product']} /* TheGameIsLyingUITests.xctest */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
{''.join(extra_groups)}/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{ids['app_target']} /* TheGameIsLying */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {ids['cfg_app']} /* Build configuration list for PBXNativeTarget "TheGameIsLying" */;
			buildPhases = (
				{ids['src_app']} /* Sources */,
				{ids['fw_app']} /* Frameworks */,
				{ids['res_app']} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = TheGameIsLying;
			productName = TheGameIsLying;
			productReference = {ids['app_product']} /* TheGameIsLying.app */;
			productType = "com.apple.product-type.application";
		}};
		{ids['test_target']} /* TheGameIsLyingTests */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {ids['cfg_test']} /* Build configuration list for PBXNativeTarget "TheGameIsLyingTests" */;
			buildPhases = (
				{ids['src_test']} /* Sources */,
				{ids['fw_test']} /* Frameworks */,
				{ids['res_test']} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				{ids['dep']} /* PBXTargetDependency */,
			);
 mar			name = TheGameIsLyingTests;
			productName = TheGameIsLyingTests;
			productReference = {ids['test_product']} /* TheGameIsLyingTests.xctest */;
			productType = "com.apple.product-type.bundle.unit-test";
		}};
		{ids['uitest_target']} /* TheGameIsLyingUITests */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {ids['cfg_uitest']} /* Build configuration list for PBXNativeTarget "TheGameIsLyingUITests" */;
			buildPhases = (
				{ids['src_uitest']} /* Sources */,
				{ids['fw_uitest']} /* Frameworks */,
				{ids['res_uitest']} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
				{ids['dep_ui']} /* PBXTargetDependency */,
			);
			name = TheGameIsLyingUITests;
			productName = TheGameIsLyingUITests;
			productReference = {ids['uitest_product']} /* TheGameIsLyingUITests.xctest */;
			productType = "com.apple.product-type.bundle.ui-testing";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{ids['project']} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 2600;
				LastUpgradeCheck = 2600;
				TargetAttributes = {{
					{ids['app_target']} = {{
						CreatedOnToolsVersion = 26.0;
					}};
					{ids['test_target']} = {{
						CreatedOnToolsVersion = 26.0;
						TestTargetID = {ids['app_target']};
					}};
					{ids['uitest_target']} = {{
						CreatedOnToolsVersion = 26.0;
						TestTargetID = {ids['app_target']};
					}};
				}};
			}};
			buildConfigurationList = {ids['cfg_proj']} /* Build configuration list for PBXProject "TheGameIsLying" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {ids['root']};
			productRefGroup = {ids['products']} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{ids['app_target']} /* TheGameIsLying */,
				{ids['test_target']} /* TheGameIsLyingTests */,
				{ids['uitest_target']} /* TheGameIsLyingUITests */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{ids['res_app']} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{app_resources} mar			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{ids['res_test']} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{ids['res_uitest']} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{ids['src_app']} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{app_sources}			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{ids['src_test']} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{test_sources}			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
		{ids['src_uitest']} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
{uitest_sources}			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin PBXTargetDependency section */
		{ids['dep']} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = {ids['app_target']} /* TheGameIsLying */;
			targetProxy = {ids['proxy']} /* PBXContainerItemProxy */;
		}};
		{ids['dep_ui']} /* PBXTargetDependency */ = {{
			isa = PBXTargetDependency;
			target = {ids['app_target']} /* TheGameIsLying */;
			targetProxy = {ids['proxy_ui']} /* PBXContainerItemProxy */;
		}};
/* End PBXTargetDependency section */

/* Begin XCBuildConfiguration section */
		{ids['debug_proj']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
				SWIFT_VERSION = 5.0;
			}};
			name = Debug;
		}};
		{ids['release_proj']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_NO_COMMON_BLOCKS = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				SDKROOT = iphoneos;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_VERSION = 5.0;
				VALIDATE_PRODUCT = YES;
			}};
			name = Release;
		}};
		{ids['debug_app']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = U27LCR7249;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = "The Game Is Lying";
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.puzzle-games";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UIRequiresFullScreen = YES;
				INFOPLIST_KEY_UIStatusBarStyle = UIStatusBarStyleLightContent;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.thegameislying.mvp;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
			}};
			name = Debug;
		}};
		{ids['release_app']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = U27LCR7249;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_KEY_CFBundleDisplayName = "The Game Is Lying";
				INFOPLIST_KEY_LSApplicationCategoryType = "public.app-category.puzzle-games";
				INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES;
				INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents = YES;
				INFOPLIST_KEY_UILaunchScreen_Generation = YES;
				INFOPLIST_KEY_UIRequiresFullScreen = YES;
				INFOPLIST_KEY_UIStatusBarStyle = UIStatusBarStyleLightContent;
				INFOPLIST_KEY_UISupportedInterfaceOrientations = UIInterfaceOrientationPortrait;
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.thegameislying.mvp;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SUPPORTS_MACCATALYST = NO;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
			}};
			name = Release;
		}};
		{ids['debug_test']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = U27LCR7249;
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.thegameislying.mvp.tests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/TheGameIsLying.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/TheGameIsLying";
			}};
			name = Debug;
		}};
		{ids['release_test']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				BUNDLE_LOADER = "$(TEST_HOST)";
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = U27LCR7249;
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.thegameislying.mvp.tests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
				TEST_HOST = "$(BUILT_PRODUCTS_DIR)/TheGameIsLying.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/TheGameIsLying";
			}};
			name = Release;
		}};
		{ids['debug_uitest']} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = U27LCR7249;
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.thegameislying.mvp.uitests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
				TEST_TARGET_NAME = TheGameIsLying;
			}};
			name = Debug;
		}};
		{ids['release_uitest']} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_TEAM = U27LCR7249;
				GENERATE_INFOPLIST_FILE = YES;
				IPHONEOS_DEPLOYMENT_TARGET = 17.0;
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.thegameislying.mvp.uitests;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_VERSION = 5.0;
				TARGETED_DEVICE_FAMILY = 1;
				TEST_TARGET_NAME = TheGameIsLying;
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{ids['cfg_proj']} /* Build configuration list for PBXProject "TheGameIsLying" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{ids['debug_proj']} /* Debug */,
				{ids['release_proj']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{ids['cfg_app']} /* Build configuration list for PBXNativeTarget "TheGameIsLying" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{ids['debug_app']} /* Debug */,
				{ids['release_app']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{ids['cfg_test']} /* Build configuration list for PBXNativeTarget "TheGameIsLyingTests" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{ids['debug_test']} /* Debug */,
				{ids['release_test']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{ids['cfg_uitest']} /* Build configuration list for PBXNativeTarget "TheGameIsLyingUITests" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{ids['debug_uitest']} /* Debug */,
				{ids['release_uitest']} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {ids['project']} /* Project object */;
}}
"""
    pbx = pbx.replace(" mar", "")
    PROJ.mkdir(parents=True, exist_ok=True)
    (PROJ / "project.pbxproj").write_text(pbx)

    scheme = f"""<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion = "2600" version = "1.7">
   <BuildAction parallelizeBuildables = "YES" buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry buildForTesting = "YES" buildForRunning = "YES" buildForProfiling = "YES" buildForArchiving = "YES" buildForAnalyzing = "YES">
            <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "{ids['app_target']}" BuildableName = "TheGameIsLying.app" BlueprintName = "TheGameIsLying" ReferencedContainer = "container:TheGameIsLying.xcodeproj"></BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv = "YES" shouldAutocreateTestPlan = "YES">
      <Testables>
         <TestableReference skipped = "NO">
            <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "{ids['test_target']}" BuildableName = "TheGameIsLyingTests.xctest" BlueprintName = "TheGameIsLyingTests" ReferencedContainer = "container:TheGameIsLying.xcodeproj"></BuildableReference>
         </TestableReference>
         <TestableReference skipped = "NO">
            <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "{ids['uitest_target']}" BuildableName = "TheGameIsLyingUITests.xctest" BlueprintName = "TheGameIsLyingUITests" ReferencedContainer = "container:TheGameIsLying.xcodeproj"></BuildableReference>
         </TestableReference>
      </Testables>
   </TestAction>
   <LaunchAction buildConfiguration = "Debug" selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB" launchStyle = "0" useCustomWorkingDirectory = "NO" ignoresPersistentStateOnLaunch = "NO" debugDocumentVersioning = "YES" debugServiceExtension = "internal" allowLocationSimulation = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "{ids['app_target']}" BuildableName = "TheGameIsLying.app" BlueprintName = "TheGameIsLying" ReferencedContainer = "container:TheGameIsLying.xcodeproj"></BuildableReference>
      </BuildableProductRunnable>
   </LaunchAction>
   <ProfileAction buildConfiguration = "Release" shouldUseLaunchSchemeArgsEnv = "YES" savedToolIdentifier = "" useCustomWorkingDirectory = "NO" debugDocumentVersioning = "YES">
      <BuildableProductRunnable runnableDebuggingMode = "0">
         <BuildableReference BuildableIdentifier = "primary" BlueprintIdentifier = "{ids['app_target']}" BuildableName = "TheGameIsLying.app" BlueprintName = "TheGameIsLying" ReferencedContainer = "container:TheGameIsLying.xcodeproj"></BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction buildConfiguration = "Debug"></AnalyzeAction>
   <ArchiveAction buildConfiguration = "Release" revealArchiveInOrganizer = "YES"></ArchiveAction>
</Scheme>
"""
    scheme_path = PROJ / "xcshareddata/xcschemes/TheGameIsLying.xcscheme"
    scheme_path.parent.mkdir(parents=True, exist_ok=True)
    scheme_path.write_text(scheme)
    print(f"Wrote {PROJ / 'project.pbxproj'}")
    print(f"App swift: {len(swift_app)} Test swift: {len(swift_test)} UITest swift: {len(swift_uitest)}")


if __name__ == "__main__":
    main()
