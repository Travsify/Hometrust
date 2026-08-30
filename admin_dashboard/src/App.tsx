import React, { useState, useEffect } from 'react';
import { Sidebar } from './components/Sidebar';
import { Header } from './components/Header';
import { LoginModal } from './components/LoginModal';
import { DashboardPage } from './pages/Dashboard';
import { VerificationsPage } from './pages/Verifications';
import { DevelopersPage } from './pages/Developers';
import { PropertiesPage } from './pages/Properties';
import { ProjectsPage } from './pages/Projects';
import { PaymentsPage } from './pages/Payments';
import { BankingPage } from './pages/Banking';
import { MaterialsPage } from './pages/Materials';
import { LegalRequestsPage } from './pages/LegalRequests';
import { InspectionsPage } from './pages/Inspections';
import { UsersPage } from './pages/Users';
import { AuditLogsPage } from './pages/AuditLogs';
import { SettingsPage } from './pages/Settings';
import { getDashboardMetrics } from './services/api';

export const App: React.FC = () => {
  const [currentTab, setCurrentTab] = useState<string>('dashboard');
  const [dashboardData, setDashboardData] = useState<any>(null);
  const [currentUser, setCurrentUser] = useState<any>(null);
  const [showLoginModal, setShowLoginModal] = useState<boolean>(false);

  useEffect(() => {
    const savedUser = localStorage.getItem('hometrust_admin_user') || localStorage.getItem('estateverify_admin_user');
    const token = localStorage.getItem('hometrust_admin_token') || localStorage.getItem('estateverify_admin_token');

    if (savedUser && token) {
      try {
        setCurrentUser(JSON.parse(savedUser));
        setShowLoginModal(false);
      } catch (e) {
        setShowLoginModal(true);
      }
    } else {
      setShowLoginModal(true);
    }
  }, []);

  const fetchMetrics = async () => {
    try {
      const data = await getDashboardMetrics();
      setDashboardData(data);
    } catch (err) {
      console.error('Failed to load metrics:', err);
    }
  };

  useEffect(() => {
    if (currentUser) {
      fetchMetrics();
    }
  }, [currentUser]);

  const handleLoginSuccess = (user: any) => {
    setCurrentUser(user);
    setShowLoginModal(false);
    fetchMetrics();
  };

  const handleLogout = () => {
    localStorage.removeItem('hometrust_admin_token');
    localStorage.removeItem('hometrust_admin_user');
    localStorage.removeItem('estateverify_admin_token');
    localStorage.removeItem('estateverify_admin_user');
    setCurrentUser(null);
    setShowLoginModal(true);
  };

  const getPageHeader = () => {
    switch (currentTab) {
      case 'dashboard':
        return { title: 'Executive Overview', subtitle: 'Real-time performance, verification volume and transaction ledger' };
      case 'verifications':
        return { title: 'Verification Request Queue', subtitle: 'OpenRouter AI preliminary scan inspection & internal legal certification' };
      case 'developers':
        return { title: 'Verified Developers & Onboarding', subtitle: 'Corporate CAC audits, identity validation & director profiles' };
      case 'properties':
        return { title: 'Property Inventory Catalog', subtitle: 'Active listings, land titles and instalment plans' };
      case 'projects':
        return { title: 'Off-Plan Construction Projects', subtitle: 'Architectural milestones and construction progress tracking' };
      case 'payments':
        return { title: 'Payments & Revenue Ledger', subtitle: 'Paystack, Flutterwave & Fincra reconciliation records' };
      case 'banking':
        return { title: 'Dedicated Virtual Banking & KYB/KYC', subtitle: 'Fincra Dedicated NUBAN Accounts & Developer Bank Payouts' };
      case 'materials':
        return { title: 'National Building Material Price Index', subtitle: 'Live audited construction market prices across 36 Nigerian States + FCT' };
      case 'legal':
        return { title: 'Legal Drafting Console', subtitle: 'Hometrust internal legal team drafting & document delivery' };
      case 'inspections':
        return { title: 'Physical Site Inspections', subtitle: 'Buyer & developer viewing schedule management' };
      case 'users':
        return { title: 'User Account & Role Management', subtitle: 'Manage buyers, developers, internal staff and access roles' };
      case 'audit':
        return { title: 'Security & Regulatory Audit Logs', subtitle: 'Tamper-evident operational audit trail' };
      case 'settings':
        return { title: 'Platform Fee & System Settings', subtitle: 'Configurable transaction service charges' };
      default:
        return { title: 'Hometrust Admin Console', subtitle: 'Management Dashboard' };
    }
  };

  const headerInfo = getPageHeader();

  return (
    <div className="flex h-screen bg-slate-950 text-slate-100 overflow-hidden font-['Plus_Jakarta_Sans',sans-serif]">
      {showLoginModal && <LoginModal onSuccess={handleLoginSuccess} />}

      <Sidebar
        currentTab={currentTab}
        setCurrentTab={setCurrentTab}
        currentUser={currentUser}
        onLogout={handleLogout}
      />

      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        <Header
          title={headerInfo.title}
          subtitle={headerInfo.subtitle}
          user={currentUser}
          onRefresh={fetchMetrics}
          onLogout={handleLogout}
        />

        <main className="flex-1 overflow-y-auto p-8">
          {currentTab === 'dashboard' && <DashboardPage data={dashboardData} onNavigate={setCurrentTab} />}
          {currentTab === 'verifications' && <VerificationsPage />}
          {currentTab === 'developers' && <DevelopersPage />}
          {currentTab === 'properties' && <PropertiesPage />}
          {currentTab === 'projects' && <ProjectsPage />}
          {currentTab === 'payments' && <PaymentsPage />}
          {currentTab === 'banking' && <BankingPage />}
          {currentTab === 'materials' && <MaterialsPage />}
          {currentTab === 'legal' && <LegalRequestsPage />}
          {currentTab === 'inspections' && <InspectionsPage />}
          {currentTab === 'users' && <UsersPage />}
          {currentTab === 'audit' && <AuditLogsPage />}
          {currentTab === 'settings' && <SettingsPage />}
        </main>
      </div>
    </div>
  );
};
