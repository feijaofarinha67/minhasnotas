// Chart initialization
document.addEventListener('DOMContentLoaded', function() {
    initCharts();
});

function initCharts() {
    // Completion Rate Chart
    const completionCtx = document.getElementById('completionChart').getContext('2d');
    new Chart(completionCtx, {
        type: 'doughnut',
        data: {
            labels: ['Completed', 'In Progress', 'Not Started'],
            datasets: [{
                data: [68, 22, 10],
                backgroundColor: ['#28a745', '#ff9900', '#dc3545'],
                borderWidth: 0
            }]
        },
        options: {
            responsive: true,
            plugins: {
                legend: {
                    position: 'bottom'
                }
            }
        }
    });

    // Skill Distribution Chart
    const skillCtx = document.getElementById('skillChart').getContext('2d');
    new Chart(skillCtx, {
        type: 'bar',
        data: {
            labels: ['EC2', 'Lambda', 'S3', 'RDS', 'VPC', 'IAM'],
            datasets: [{
                label: 'Skill Level',
                data: [85, 92, 78, 65, 88, 73],
                backgroundColor: '#ff9900',
                borderRadius: 5
            }]
        },
        options: {
            responsive: true,
            scales: {
                y: {
                    beginAtZero: true,
                    max: 100
                }
            },
            plugins: {
                legend: {
                    display: false
                }
            }
        }
    });
}

// Modal functionality
const modal = document.getElementById('infoModal');
const modalTitle = document.getElementById('modalTitle');
const modalText = document.getElementById('modalText');

const infoData = {
    journey: {
        title: 'Start Your AWS Journey',
        text: 'Begin with our comprehensive onboarding program. Complete skill assessments, choose your learning path, and start earning points immediately. Join thousands of cloud professionals advancing their careers!'
    },
    ec2: {
        title: 'EC2 Mastery Challenge',
        text: 'Master Amazon EC2 with hands-on labs covering instance types, security groups, load balancing, and auto-scaling. Duration: 2-3 hours. Prerequisites: Basic AWS knowledge. Earn 500 points upon completion.'
    },
    serverless: {
        title: 'Serverless Solutions',
        text: 'Build modern applications using AWS Lambda, API Gateway, and DynamoDB. Learn event-driven architecture, cost optimization, and monitoring. Duration: 4-5 hours. Intermediate level required.'
    },
    security: {
        title: 'Security Deep Dive',
        text: 'Implement advanced security practices including IAM policies, encryption, VPC security, and compliance frameworks. Duration: 6-8 hours. Advanced level challenge with real-world scenarios.'
    },
    leader1: {
        title: 'CloudMaster Profile',
        text: 'Top performer with expertise in multi-cloud architectures. Completed 47 challenges, specializes in DevOps and Infrastructure as Code. Active mentor in the community with 98% challenge success rate.'
    },
    leader2: {
        title: 'ServerlessGuru Profile',
        text: 'Serverless architecture specialist with deep Lambda and API Gateway knowledge. Completed 43 challenges, focuses on cost optimization and performance tuning. Community contributor and workshop leader.'
    },
    leader3: {
        title: 'DevOpsNinja Profile',
        text: 'CI/CD pipeline expert with strong automation skills. Completed 41 challenges, specializes in containerization and orchestration. Known for innovative solutions and helping other participants.'
    },
    realtime: {
        title: 'Real-time Analytics',
        text: 'Monitor your learning progress with detailed dashboards showing completion rates, skill improvements, time spent, and performance comparisons. Get personalized recommendations for your next challenges.'
    },
    community: {
        title: 'Community Driven Learning',
        text: 'Connect with over 15,000 cloud professionals worldwide. Share solutions, participate in discussions, join study groups, and learn from industry experts. Collaborative learning accelerates your growth.'
    },
    handson: {
        title: 'Hands-on Learning Experience',
        text: 'Practice with real AWS environments in our sandbox. No setup required - instant access to pre-configured labs with guided instructions. Learn by doing with immediate feedback and validation.'
    }
};

function showInfo(type) {
    const info = infoData[type];
    if (info) {
        modalTitle.textContent = info.title;
        modalText.textContent = info.text;
        modal.style.display = 'block';
    }
}

function closeModal() {
    modal.style.display = 'none';
}

// Close modal when clicking outside
window.onclick = function(event) {
    if (event.target === modal) {
        modal.style.display = 'none';
    }
}

// Smooth scrolling for navigation
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Add loading animation for stats
function animateStats() {
    const statCards = document.querySelectorAll('.stat-card h3');
    statCards.forEach((stat, index) => {
        const finalValue = stat.textContent;
        stat.textContent = '0';
        
        setTimeout(() => {
            let current = 0;
            const target = parseInt(finalValue.replace(/,/g, '')) || finalValue;
            const increment = typeof target === 'number' ? target / 50 : 0;
            
            const timer = setInterval(() => {
                if (typeof target === 'number') {
                    current += increment;
                    if (current >= target) {
                        stat.textContent = finalValue;
                        clearInterval(timer);
                    } else {
                        stat.textContent = Math.floor(current).toLocaleString();
                    }
                } else {
                    stat.textContent = finalValue;
                    clearInterval(timer);
                }
            }, 20);
        }, index * 200);
    });
}

// Trigger stats animation when page loads
window.addEventListener('load', () => {
    setTimeout(animateStats, 500);
});