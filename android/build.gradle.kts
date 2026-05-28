allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    val injectNamespace = {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                val getNamespace = android.javaClass.getMethod("getNamespace")
                val setNamespace = android.javaClass.getMethod("setNamespace", String::class.java)
                if (getNamespace.invoke(android) == null) {
                    val cleanName = project.name.replace(Regex("[^a-zA-Z0-9]"), "")
                    setNamespace.invoke(android, "dev.isar.$cleanName")
                }
            } catch (e: Exception) {
                // Abaikan jika library versi lama tidak mendukung metode ini
            }

            // Hapus atribut package dari AndroidManifest.xml library di pub-cache sebelum diproses oleh AGP 8
            project.tasks.matching { it.name.startsWith("process") && it.name.endsWith("Manifest") }.configureEach {
                doFirst {
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        try {
                            var content = manifestFile.readText()
                            if (content.contains("package=\"")) {
                                content = content.replace(Regex("""package="[^"]+""""), "")
                                manifestFile.writeText(content)
                            }
                        } catch (e: Exception) {
                            // Abaikan jika gagal memodifikasi manifest (misal permission read-only)
                        }
                    }
                }
            }
        }
    }
    if (project.state.executed) {
        injectNamespace()
    } else {
        project.afterEvaluate {
            injectNamespace()
        }
    }
}
