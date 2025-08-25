module.exports = {
    reporterEnabled: 'jest-junit',
    jestJunit: {
        outputDirectory: '.',
        outputName: 'test-results.xml',
        classNameTemplate: '{classname}',
        titleTemplate: '{title}',
        ancestorSeparator: ' › ',
        usePathForSuiteName: true
    }
};
