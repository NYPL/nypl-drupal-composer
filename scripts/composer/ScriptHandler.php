<?php

/**
 * @file
 * Contains \DrupalProject\composer\ScriptHandler.
 */

namespace DrupalProject\composer;

use Composer\Script\Event;
use Composer\Semver\Comparator;
use DrupalFinder\DrupalFinder;
use Symfony\Component\Filesystem\Filesystem;
use Symfony\Component\Finder\Finder;
use Webmozart\PathUtil\Path;

class ScriptHandler
{

  protected static function getDrupalRoot($project_root)
  {
    return $project_root . '/web';
  }

  public static function createRequiredFiles(Event $event)
  {
    $fs = new Filesystem();
    $drupalFinder = new DrupalFinder();
    $drupalFinder->locateRoot(getcwd());
    $drupalRoot = $drupalFinder->getDrupalRoot();
    $event->getIO()->write("Drupal root identified as: $drupalRoot");

    $dirs = [
      'modules',
      'profiles',
      'themes',
    ];

    // Required for unit testing
    foreach ($dirs as $dir) {
      if (!$fs->exists($drupalRoot . '/' . $dir)) {
        $fs->mkdir($drupalRoot . '/' . $dir);
      }
      $fs->touch($drupalRoot . '/' . $dir . '/.gitkeep');
    }

    // Prepare the settings file for installation
    if (!$fs->exists($drupalRoot . '/sites/default/settings.php') && $fs->exists($drupalRoot . '/sites/default/default.settings.php')) {
      $fs->copy($drupalRoot . '/sites/default/default.settings.php', $drupalRoot . '/sites/default/settings.php');
      // Insert our homegrown settings file if it exists.
      if ($fs->exists('/tmp/settings.php')) {
        $fs->copy('/tmp/settings.php', $drupalRoot . '/sites/default/settings.php');
        $event->getIO()->write("Copied custom /tmp/settings.php to sites/default");
      }
      else {
        $event->getIO()->write("Failed to copy custom /tmp/settings.php to sites/default");
      }
      // Insert local settings for database connection and local development settings.
      if ($fs->exists('/tmp/settings.local.php')) {
        $fs->copy('/tmp/settings.local.php', $drupalRoot . '/sites/default/settings.local.php');
        $fs->chmod($drupalRoot . '/sites/default/settings.local.php', 0666);
        $event->getIO()->write("Copied /tmp/settings.local.php to sites/default");
      }
      else {
        $event->getIO()->write("Failed to copy /tmp/settings.local.php to sites/default");
      }
      // Add the basic services.yml based on the default.services.yml file.
      if ($fs->exists('/tmp/services.yml')) {
        $fs->copy('/tmp/services.yml', $drupalRoot . '/sites/default/services.yml');
        $fs->chmod($drupalRoot . '/sites/default/services.yml', 0666);
        $event->getIO()->write("Copied /tmp/services.yml to sites/default");
      }
      else {
        $event->getIO()->write("Failed to copy /tmp/services.yml to sites/default");
      }
      require_once $drupalRoot . '/core/includes/bootstrap.inc';
      require_once $drupalRoot . '/core/includes/install.inc';
      $settings['config_directories'] = [
        CONFIG_SYNC_DIRECTORY => (object) [
          'value' => Path::makeRelative($drupalFinder->getComposerRoot() . '/config/sync', $drupalRoot),
          'required' => TRUE,
        ],
      ];
      drupal_rewrite_settings($settings, $drupalRoot . '/sites/default/settings.php');
      $fs->chmod($drupalRoot . '/sites/default/settings.php', 0666);
      if ($fs->exists($drupalRoot . '/sites/default/settings.php')) {
        $event->getIO()->write("Created a sites/default/settings.php file with chmod 0666");
      }
      else {
        $event->getIO()->write("Failed to create a sites/default/settings.php file with chmod 0666");
      }
    }

    // Create the files directory with chmod 0777
    if (!$fs->exists($drupalRoot . '/sites/default/files')) {
      $oldmask = umask(0);
      $fs->mkdir($drupalRoot . '/sites/default/files', 0777);
      umask($oldmask);
      if ($fs->exists($drupalRoot . '/sites/default/files')) {
        $event->getIO()->write("Created a sites/default/files directory with chmod 0777");
      }
      else {
        $event->getIO()->write("Failed to create a sites/default/files directory with chmod 0777");
      }
    }
  }

  // This is called by the QuickSilver deploy hook to convert from
  // a 'lean' repository to a 'fat' repository. This should only be
  // called when using this repository as a custom upstream, and
  // updating it with `terminus composer <site>.<env> update`. This
  // is not used in the GitHub PR workflow.
  public static function prepareForPantheon()
  {
    // Get rid of any .git directories that Composer may have added.
    // n.b. Ideally, there are none of these, as removing them may
    // impair Composer's ability to update them later. However, leaving
    // them in place prevents us from pushing to Pantheon.
    $dirsToDelete = [];
    $finder = new Finder();
    foreach (
      $finder
        ->directories()
        ->in(getcwd())
        ->ignoreDotFiles(false)
        ->ignoreVCS(false)
        ->depth('> 0')
        ->name('.git')
      as $dir) {
      $dirsToDelete[] = $dir;
    }
    $fs = new Filesystem();
    $fs->remove($dirsToDelete);

    // Fix up .gitignore: remove everything above the "::: cut :::" line
    $gitignoreFile = getcwd() . '/.gitignore';
    $gitignoreContents = file_get_contents($gitignoreFile);
    $gitignoreContents = preg_replace('/.*::: cut :::*/s', '', $gitignoreContents);
    file_put_contents($gitignoreFile, $gitignoreContents);
  }

  /**
   * Checks if the installed version of Composer is compatible.
   *
   * Composer 1.0.0 and higher consider a `composer install` without having a
   * lock file present as equal to `composer update`. We do not ship with a lock
   * file to avoid merge conflicts downstream, meaning that if a project is
   * installed with an older version of Composer the scaffolding of Drupal will
   * not be triggered. We check this here instead of in drupal-scaffold to be
   * able to give immediate feedback to the end user, rather than failing the
   * installation after going through the lengthy process of compiling and
   * downloading the Composer dependencies.
   *
   * @see https://github.com/composer/composer/pull/5035
   */
  public static function checkComposerVersion(Event $event) {
    $composer = $event->getComposer();
    $io = $event->getIO();

    $version = $composer::VERSION;

    // The dev-channel of composer uses the git revision as version number,
    // try to the branch alias instead.
    if (preg_match('/^[0-9a-f]{40}$/i', $version)) {
      $version = $composer::BRANCH_ALIAS_VERSION;
    }

    // If Composer is installed through git we have no easy way to determine if
    // it is new enough, just display a warning.
    if ($version === '@package_version@' || $version === '@package_branch_alias_version@') {
      $io->writeError('<warning>You are running a development version of Composer. If you experience problems, please update Composer to the latest stable version.</warning>');
    }
    elseif (Comparator::lessThan($version, '1.0.0')) {
      $io->writeError('<error>Drupal-project requires Composer version 1.0.0 or higher. Please update your Composer before continuing</error>.');
      exit(1);
    }
  }

}
