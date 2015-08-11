
// Require

var gulp       = require('gulp'),
    gutil      = require('gulp-util'),
    browserify = require('browserify'),
    connect    = require('gulp-connect'),
    source     = require('vinyl-source-stream');


// Helpers

function reload (files) {
  gulp.src(files.path).pipe(connect.reload());
}

function prettyLog (label, text) {
  gutil.log( gutil.colors.bold("  " + label + " | ") + text );
}

function errorReporter (err){
  gutil.log( gutil.colors.red("Error: ") + gutil.colors.yellow(err.plugin) );
  if (err.message)    { prettyLog("message", err.message); }
  if (err.fileName)   { prettyLog("in file", err.fileName); }
  if (err.lineNumber) { prettyLog("on line", err.lineNumber); }
  return this.emit('end');
};


// Preconfigure bundler

var master = browserify({
  debug: true,
  cache: {},
  packageCache: {},
  entries: [ './src/index.ls' ],
  extensions: '.ls'
});

var client = browserify({
  debug: true,
  cache: {},
  packageCache: {},
  entries: [ './src/client/index.ls' ],
  extensions: '.ls'
});



// Tasks

gulp.task('server', function () {
  connect.server({
    root: 'public',
    livereload: true
  });
});

gulp.task('master', function () {
  return master
    .bundle()
    .on('error', errorReporter)
    .pipe(source('app.js'))
    .pipe(gulp.dest('public'))
});

gulp.task('client', function () {
  return client
    .bundle()
    .on('error', errorReporter)
    .pipe(source('client.js'))
    .pipe(gulp.dest('public'))
});


// Register

gulp.task('default', [ 'server', 'master', 'client' ], function () {
  gulp.watch(['src/**/*.ls', '!src/client/*.ls', 'test/**/*.ls'], [ 'master' ]);
  gulp.watch(['src/client/*.ls'], [ 'client' ]);
  gulp.watch(['public/**/*']).on('change', reload);
});

