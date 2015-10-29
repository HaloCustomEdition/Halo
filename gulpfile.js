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
           header: '<html><head></head><body><div class="container"><a href="https://github.com/HaloCustomEdition/Halo"><img style="position: absolute; top: 0; left: 0; border: 0;" src="https://camo.githubusercontent.com/567c3a48d796e2fc06ea80409cc9dd82bf714434/68747470733a2f2f73332e616d617a6f6e6177732e636f6d2f6769746875622f726962626f6e732f666f726b6d655f6c6566745f6461726b626c75655f3132313632312e706e67" alt="Fork me on GitHub" data-canonical-src="https://s3.amazonaws.com/github/ribbons/forkme_left_darkblue_121621.png"></a>\n',
           footer: '</div></body></html>\n'
        }))
        .pipe(cheerio(function ($, file) {
          $("head").append("<link rel='stylesheet' href='https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css'  type='text/css'>");
        }))
        .pipe(gulp.dest('out'));
});
