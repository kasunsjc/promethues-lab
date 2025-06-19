// Simple JavaScript file for the k6 load testing demo
console.log('Script loaded');

// Simulate some JavaScript processing
function processData() {
    console.log('Processing data...');
    
    // Create a large array to simulate memory usage
    const data = [];
    for (let i = 0; i < 10000; i++) {
        data.push({
            id: i,
            value: Math.random() * 1000,
            text: `Item ${i}`
        });
    }
    
    // Do some processing
    const results = data.map(item => {
        return {
            id: item.id,
            processed: item.value * 2,
            category: item.value > 500 ? 'high' : 'low'
        };
    });
    
    // Filter some results
    const highValues = results.filter(item => item.category === 'high');
    
    console.log(`Processed ${data.length} items`);
    console.log(`Found ${highValues.length} high values`);
}

// Add an event listener
document.addEventListener('DOMContentLoaded', () => {
    console.log('DOM loaded');
    
    // Set up click handlers
    const buttons = document.querySelectorAll('button');
    buttons.forEach(button => {
        button.addEventListener('click', () => {
            console.log('Button clicked');
            processData();
        });
    });
    
    // Simulate some delayed execution
    setTimeout(() => {
        console.log('Timeout executed');
    }, 2000);
});
