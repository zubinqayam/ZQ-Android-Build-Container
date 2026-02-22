@rem =============================================================================
@rem gradlew.bat  –  Gradle wrapper launch script (Windows)
@rem PLACEHOLDER – see gradle/wrapper/gradle-wrapper.properties for instructions
@rem               on how to replace this with a real wrapper.
@rem =============================================================================
@echo off

set JAR=%~dp0gradle\wrapper\gradle-wrapper.jar

if not exist "%JAR%" (
    echo.
    echo ====================================================================
    echo   gradle\wrapper\gradle-wrapper.jar is missing.
    echo.
    echo   This file is a PLACEHOLDER.  Generate the real Gradle wrapper by
    echo   running:
    echo.
    echo     gradle wrapper --gradle-version 8.7 --distribution-type all
    echo.
    echo   Then commit gradlew, gradlew.bat, gradle\wrapper\gradle-wrapper.jar
    echo   and gradle\wrapper\gradle-wrapper.properties.
    echo ====================================================================
    echo.
    exit /b 1
)

java -jar "%JAR%" %*
