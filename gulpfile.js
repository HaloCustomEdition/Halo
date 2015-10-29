var gulp = require('gulp');
var markdown = require('gulp-markdown');
var rename = require('gulp-rename');
var wrapper = require('gulp-wrapper');
var cheerio = require('gulp-cheerio');

gulp.task('default', function () {
    return gulp.src('README.md')
        .pipe(markdown())
        .pipe(rename('index.html'))
        .pipe(wrapper({
           header: '<html><head></head><body><div class="container">\n',
           footer: '</div></body></html>\n'
        }))
        .pipe(cheerio(function ($, file) {
          $("head").append("<link rel='stylesheet' href='https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css'  type='text/css'>");
        }))
        .pipe(gulp.dest('out'));
});
